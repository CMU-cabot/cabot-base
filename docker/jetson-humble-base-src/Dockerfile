ARG FROM_IMAGE=nvcr.io/nvidia/l4t-base:r35.1.0

FROM $FROM_IMAGE as build

ARG ROS_PKG=ros_base
ENV ROS_DISTRO=humble
ENV ROS_ROOT=/opt/ros/${ROS_DISTRO}

# CMake 3.20+ is required to build ROS2
ARG CMAKE_V=3.20.6

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp

RUN locale-gen en_US en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8

RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 1

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	curl \
	wget \
	gnupg2 \
	lsb-release \
	ca-certificates \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get clean

RUN export ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}') ;\
	curl -L -s -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb" \
	&& apt-get update \
	&& apt-get install /tmp/ros2-apt-source.deb \
	&& rm -f /tmp/ros2-apt-source.deb \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get clean

RUN apt-get update && \
	apt-get install -y --no-install-recommends \
	build-essential \
	git \
	libbullet-dev \
	libpython3-dev \
	libasio-dev \
	libtinyxml2-dev \
	python3-colcon-common-extensions \
	python3-flake8 \
	python3-numpy \
	python3-pip \
	python3-pytest-cov \
	python3-rosdep \
	python3-rosinstall-generator \
	python3-setuptools \
	python3-vcstool \
	&& rm -rf /var/lib/apt/lists/* \
	&& apt-get clean

RUN python3 -m pip install -U \
	argcomplete \
	flake8-blind-except \
	flake8-builtins \
	flake8-class-newline \
	flake8-comprehensions \
	flake8-deprecated \
	flake8-docstrings \
	flake8-import-order \
	flake8-quotes \
	pytest-repeat \
	pytest-rerunfailures \
	pytest

# install cmake
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_V}/cmake-${CMAKE_V}-linux-aarch64.sh && \
    sh cmake-${CMAKE_V}-linux-aarch64.sh --skip-license --prefix=/usr && \
    rm cmake-${CMAKE_V}-linux-aarch64.sh

# build ROS2
RUN mkdir -p ${ROS_ROOT}/src && \
	cd ${ROS_ROOT} && \
	# https://answers.ros.org/question/325245/minimal-ros2-installation/?answer=325249#post-id-325249
	rosinstall_generator --deps --rosdistro ${ROS_DISTRO} ${ROS_PKG} \
	launch_xml \
	launch_yaml \
	launch_testing \
	launch_testing_ament_cmake \
	demo_nodes_cpp \
	demo_nodes_py \
	example_interfaces \
	camera_calibration_parsers \
	camera_info_manager \
	cv_bridge \
	v4l2_camera \
	vision_opencv \
	vision_msgs \
	image_geometry \
	image_pipeline \
	image_transport \
	compressed_image_transport \
	compressed_depth_image_transport \
	common_interfaces \
	diagnostics \
	ros2cli \
	launch_ros \
	rosidl_runtime_py \
	tf_transformations \
	pcl_conversions \
	pcl_msgs \
	pcl_ros \
	> ros2.${ROS_DISTRO}.${ROS_PKG}.rosinstall && \
	cat ros2.${ROS_DISTRO}.${ROS_PKG}.rosinstall && \
	vcs import src < ros2.${ROS_DISTRO}.${ROS_PKG}.rosinstall && \
	# https://github.com/dusty-nv/jetson-containers/issues/181
	rm -r ${ROS_ROOT}/src/ament_cmake && \
	git -C ${ROS_ROOT}/src/ clone https://github.com/ament/ament_cmake -b ${ROS_DISTRO} && \
	# install dependencies using rosdep
	apt-get update && \
	cd ${ROS_ROOT} && \
	rosdep init && \
	rosdep update && \
	rosdep install -y \
	--ignore-src \
	--from-paths src \
	--rosdistro ${ROS_DISTRO} \
	--skip-keys "libopencv-dev libopencv-contrib-dev libopencv-imgproc-dev python-opencv python3-opencv" && \
	rm -rf /var/lib/apt/lists/* && \
	apt-get clean && \
	# build it!
	colcon build \
	--merge-install \
	--cmake-args -DCMAKE_BUILD_TYPE=Release && \
	# remove build files
	rm -rf ${ROS_ROOT}/src && \
	rm -rf ${ROS_ROOT}/logs && \
	rm -rf ${ROS_ROOT}/build && \
	rm ${ROS_ROOT}/*.rosinstall

RUN pip3 install --no-cache-dir transforms3d

ENV RMW_IMPLEMENTATION=rmw_cyclonedds_cpp

COPY ./ros_entrypoint.sh /ros_entrypoint.sh

ENTRYPOINT ["/ros_entrypoint.sh"]

