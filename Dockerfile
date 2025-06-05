## To build this image, you'll need to download FreeSurfer, MNE
# and have a valid FreeSurfer license file, and put them into your scripts directory.
# To build:  cd path_to_scripts; docker build -t docker_scripts .
# To run: docker run -it -v <path_to_your_subject_folder_on_host>:/opt/processing docker_scripts /bin/bash
# Then run scripts as usual: bash main_surface -c /opt/processing/<name_of_configuration_file.sh>
# delete container and image: docker ps -a; docker rm <container_id>; docker rmi <image>
# also you can use: docker images

FROM ubuntu:22.04
#MAINTAINER timpx <timpx@eml.cc>

# /opt used during installation, but 
# /opt/scripts is final workdir, set below
WORKDIR /opt

# system packages
RUN apt-get update
RUN apt-get install -y wget curl git cmake cmake gnupg software-properties-common
RUN add-apt-repository main && \
    add-apt-repository universe && \
    add-apt-repository restricted && \
    add-apt-repository multiverse && \
    apt-get update

RUN wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    && bash Miniconda3-latest-Linux-x86_64.sh -b -p /opt/miniconda3
ENV PATH=/opt/miniconda3/bin:$PATH  

RUN conda install python=3.10
#RUN pip install nibabel mne[hdf5]

RUN wget -O- http://neuro.debian.net/lists/jammy.us-ca.full | tee /etc/apt/sources.list.d/neurodebian.sources.list
RUN apt-key adv --recv-keys --keyserver hkps://keyserver.ubuntu.com 0xA5D32F012649A5A9

#COPY ./neurodebian-archive-keyring.gpg /etc/apt/keyrings/
#RUN gpg --import /etc/apt/keyrings/neurodebian-archive-keyring.gpg

RUN apt-get update --allow-unauthenticated 
#COPY tzdata_location.sh /opt/tzdata_location.sh
#CMD ["/opt/tzdata_location.sh"]
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Vancouver
RUN DEBIAN_FRONTEND=noninteractive TZ=America/Vancouver apt-get -y install tzdata 
#RUN rm /opt/tzdata_location.sh
RUN apt-get update -qq -y 
RUN apt-get install -qq -y g++ libgsl-dev libeigen3-dev 
RUN apt-get install -y libc6 zlib1g zlib1g-dev gcc libopenblas-dev liblapacke-dev 
RUN apt-get install -y libhdf5-dev libhdf5-serial-dev libmatio-dev # libvtk6-dev 
RUN apt-get install -y libvtk7-dev doxygen 
RUN apt-get install -y libcgal-dev libgsl-dev gsl-bin swig unzip zip 
RUN apt-get install gcc libhdf5-dev

# external packages
ENV FSLDIR=/usr/share/fsl
RUN curl -Ls https://fsl.fmrib.ox.ac.uk/fsldownloads/fslconda/releases/getfsl.sh | sh -s 

COPY ./freesurfer_ubuntu22-7.4.1_amd64.deb /opt/
RUN apt-get install -y /opt/freesurfer_ubuntu22-7.4.1_amd64.deb
COPY ./license.txt /opt/freesurfer/7.4.1/license.txt

 # FS, FSL, MNE env vars 
 ENV FIX_VERTEX_AREA= \
    FREESURFER_HOME=/usr/local/freesurfer/7.4.1 \
    FSFAST_HOME=/usr/local/freesurfer/7.4.1/bin/freesurfer/fsfast \
    FSF_OUTPUT_FORMAT=nii.gz \
    FS_OVERRIDE=0 \
    LOCAL_DIR=/usr/local/freesurfer/7.4.1/local \
    MINC_BIN_DIR=/usr/local/freesurfer/7.4.1/mni/bin \
    MINC_LIB_DIR=/usr/local/freesurfer/7.4.1/mni/lib \
    SUBJECTS_DIR=/usr/local/freesurfer/7.4.1/subjects \
    MNI_DATAPATH=/usr/local/freesurfer/7.4.1/mni/data \
    MNI_DIR=/usr/local/freesurfer/7.4.1/mni \
    MNI_PERL5LIB=/usr/local/freesurfer/7.4.1/mni/share/perl5 \
    OS=Linux \
    PERL5LIB=/usr/local/freesurfer/7.4.1/mni/share/perl5 \
    MNE_ROOT=/opt/miniconda3/lib/python3.10/site-packages/mne \
    MNE_BIN_PATH=/opt/miniconda3/lib/python3.10/site-packages/mne/bin \
    MNE_LIB_PATH=/opt/miniconda3/lib/python3.10/site-packages/mne/lib \
    MNE_ROOT=/opt/miniconda3/lib/python3.10/site-packages/mne \
    XUSERFILESEARCHPATH=/opt/miniconda3/lib/python3.10/site-packages/mne4/share/app-defaults/%N \
    LD_LIBRARY_PATH=/usr/share/fsl/lib:/opt/miniconda3/lib/python3.10/site-packages/mne/lib \
    PATH=/usr/share/fsl:/usr/share/fsl/5.0/bin:/opt/MNE-2.7.0-3106-Linux-x86_64/bin:/opt/freesurfer/bin:/opt/freesurfer/fsfast/bin:/opt/freesurfer/tktools:/opt/freesurfer/mni/bin:$PATH \
    FSLDIR=/usr/share/fsl \
    FSLBROWSER=/etc/alternatives/x-www-browser \
    FSLLOCKDIR= \
    FSLMACHINELIST= \
    FSLMULTIFILEQUIT=TRUE \
    FSLOUTPUTTYPE=NIFTI_GZ \
    FSLREMOTECALL= \
    FSLTCLSH=/usr/bin/tclsh \
    FSLWISH=/usr/bin/wish \
    POSSUMDIR=/usr/share/fsl

# Mrtrix3 ----------------------
RUN conda install -c conda-forge -c MRtrix3 mrtrix3 libstdcxx-ng
# RUN git clone https://github.com/MRtrix3/mrtrix3.git /opt/mrtrix3
# RUN cd /opt/mrtrix3
# RUN ./build

# OpenMEEG ---------------------
RUN conda install -c conda-forge openmeeg
#RUN git clone https://github.com/openmeeg/openmeeg.git /opt/openmeeg \
#    && cd /opt/openmeeg/ \
#    && git checkout 2.4.prerelease \
#    && mkdir build && cd build && \
#    cmake -DBUILD_TESTING=ON -DCMAKE_BUILD_TYPE=Release \
#        -DENABLE_PYTHON=OFF -DCMAKE_INSTALL_PREFIX=/usr/local \
#        -DBLASLAPACK_IMPLEMENTATION="OpenBLAS" \
#        -DBUILD_DOCUMENTATION=OFF -DBUILD_TUTORIALS=OFF .. && \
#    make -j && \
#    make test && \
#    make install
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Py 3 stack ---------------------
RUN conda install -c conda-forge jupyterlab \
    && conda install numpy matplotlib \
    && pip install nibabel "mne[hdf5]"

# Scripts and remesher
#RUN git clone https://github.com/ins-amu/scripts.git /opt/scripts
RUN git clone https://github.com/LJWilliams/scripts.git /opt/scripts
RUN cd /opt/scripts/remesher/libremesh && make clean && cd /opt/scripts/remesher/cmdremesher && make clean && make
WORKDIR /opt/scripts
RUN mkdir /opt/processing

ENTRYPOINT ["/bin/bash", "-c", "source $FREESURFER_HOME/SetUpFreeSurfer.sh"]
CMD ["exec", "\"${@}\""]

#TODO for compatibility with tvb-make
#ENTRYPOINT ["make"]
