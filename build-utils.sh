#!/bin/bash

# Copyright (c) 2020, 2023  Carnegie Mellon University, IBM Corporation, and others
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

function red {
    echo -en "\033[31m"  ## red
    echo $@
    echo -en "\033[0m"  ## reset color
}

function blue {
    echo -en "\033[36m"  ## blue
    echo $@
    echo -en "\033[0m"  ## reset color
}

function show_available_services {
    local -n dcfiles_=$1
    declare -A services_dict
    for dcfile in ${dcfiles_[@]}; do
        services=$(docker compose -f $dcfile config --services 2> /dev/null)
        for service in ${services[@]}; do
            if [[ ! -v services_dict[$service] ]]; then
                echo "  $service"
            fi
            services_dict[$service]=1
        done
    done
}

function build_image {
    local -n dcfiles_=$1
    local -n targets_=$2
    local -n option_=$3
    local -n time_zone_=$4
    local -n uid_=$5
    local -n prefix_=$6

    if [[ ! -z $targets_ ]]; then
        # make target dict
        declare -A target_dict
        for target in ${targets_[@]}; do
            target_dict[$target]=1
        done
    fi
    blue "Building images"
    for dcfile in ${dcfiles_[@]}; do
        blue "Building $dcfile"
        services=$(docker compose -f $dcfile config --services)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        services=$(echo ${services[@]} | grep -v base)
        for service in ${services[@]}; do
            # check if target_dict exists and service is in the target_dict
            if declare -p target_dict &> /dev/null && [[ ! -v target_dict[$service] ]]; then
                continue
            fi
            blue "Building image of $dcfile, $service"
            docker compose -f $dcfile build \
                --build-arg PREFIX=$prefix_ \
                --build-arg UID=$uid_ \
                --build-arg TZ=$time_zone_ \
                $option_ \
                $service
            if [[ $? -ne 0 ]]; then
                return 1
            fi
        done
    done
}

function build_workspace {
    local -n dcfiles_=$1
    local -n targets_=$2
    local -n debug_=$3
    if [[ ! -z $targets_ ]]; then
        # make target dict
        declare -A target_dict
        for target in ${targets_[@]}; do
            target_dict[$target]=1
        done
    fi
    declare -A built

    blue "Building workspaces"
    for dcfile in ${dcfiles_[@]}; do
        blue "Building $dcfile"
        services=$(docker compose -f $dcfile config --services)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
        services=$(echo ${services[@]} | grep -v base | grep -v lint)
        for service in ${services[@]}; do
            # check if target_dict exists and service is in the target_dict
            if declare -p target_dict &> /dev/null && [[ ! -v target_dict[$service] ]]; then
                continue
            fi
            blue "Building workspace of $dcfile, $service debug=$debug_"

            # check if volume src dir is already built or not
            dirs=$(docker compose -f $dcfile config $service | grep target | grep src | cut -d: -f2)
            flag=true
            for dir in ${dirs[@]}; do
                if [[ ! -v built[$dir] ]]; then
                    flag=false
                fi
                built[$dir]=1
            done
            if $flag; then
                blue "skip -- already built"
                continue
            fi
            if [[ "$debug_" -eq 1 ]]; then
                docker compose -f $dcfile run --rm $service /launch.sh build -d
            else
                docker compose -f $dcfile run --rm $service /launch.sh build
            fi
            if [[ $? -ne 0 ]]; then
                return 1
            fi
        done
    done
}
