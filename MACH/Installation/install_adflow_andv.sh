#!/bash/bin

# make sure, openmpi is installed and runs

# ########################################
# create conda env
# ########################################
conda create -n MACH
conda install python=3.7


# ########################################
# install mpi4py & numpy
# ########################################
pip install mpi4py numpy


# ########################################
# set the proper compilers to use with mpi
# ########################################
export OMPI_CC=gcc-9
export OMPI_CXX=g++-9
export OMPI_FC=gfortran-9


# ########################################
# compile and install petsc
# ########################################
wget https://www.mcs.anl.gov/petsc/mirror/release-snapshots/petsc-3.12.5.tar.gz
tar -xvaf petsc-3.12.5.tar.gz
cd petsc-3.12.5
./configure \
    --prefix=$CONDA_PREFIX/external/petsc/ \
    --PETSC_ARCH="real-debug" \
    --with-scalar-type=real \
    --with-debugging=1 \
    --download-metis=yes \
    --download-parmetis=yes \
    --download-superlu_dist=yes \
    --with-shared-libraries=yes \
    --with-fortran-bindings=1 \
    --with-cxx-dialect=C++11

# run the build command shown in the last line
# run the install command shown in the last line
# run the test command shown in the last line

export PETSC_DIR=$CONDA_PREFIX/external/petsc/
export PETSC_ARCH=""

pip install petsc4py==3.12 --no-cache-dir


# ########################################
# Compile and Install CGNS
# ########################################
# First, we must compile and install hdf5
# git clone https://bitbucket.hdfgroup.org/scm/hdffv/hdf5.git --branch hdf5_1_12 \
    # --single-branch hdf5_1_12
wget https://support.hdfgroup.org/ftp/HDF5/releases/hdf5-1.10/hdf5-1.10.7/src/hdf5-1.10.7.tar.gz
tar -xvaf hdf5-1.10.7.tar.gz
CC=mpicc FC=mpif90 CXX=mpic++ \
    ./configure \
    --enable-fortran \
    --disable-hl \
    --prefix=$CONDA_PREFIX/external/hdf5 \
    --enable-parallel
make -j 12
make test
make install

# Now we can compile and install CGNS
wget https://github.com/CGNS/CGNS/archive/refs/tags/v4.2.0.tar.gz
tar -xvaf v4.2.0.tar.gz
cd CGNS-4.2.0/src
CC=mpicc CFLAGS="-ldl -fPIC" FC=mpif90 FCFLAGS="-ldl -fPIC" MPIEXEC="mpirun -n \$\${NPROCS:=4}" \
    ./configure \
    --prefix=$CONDA_PREFIX/external/cgns \
    --with-hdf5=$CONDA_PREFIX/external/hdf5 \
    --with-fortran  \
    --disable-cgnstools \
    --enable-parallel \
    --disable-64bit
make -j 12
make test
make install


# ########################################
# Before we compile MACH, set up all env vars
# ########################################
mkdir -p $CONDA_PREFIX/etc/conda/activate.d
mkdir -p $CONDA_PREFIX/etc/conda/deactivate.d
echo "
    export OLD_PATH=\$PATH
    export OLD_LD_LIBRARY_PATH=\$LD_LIBRARY_PATH

    export OMPI_CC=gcc-9
    export OMPI_CXX=g++-9
    export OMPI_FC=gfortran-9
    export PETSC_DIR=\$CONDA_PREFIX/external/petsc/
    export PETSC_ARCH=""
    export CGNS_HOME=\$CONDA_PREFIX/external/cgns
    export PATH=\$CGNS_HOME/bin:\$PATH:
    export LD_LIBRARY_PATH=\$CGNS_HOME/lib:\$LD_LIBRARY_PATH
    export HDF5_HOME=\$CONDA_PREFIX/external/hdf5
    export PATH=\$HDF5_HOME/bin:\$PATH:
    export LD_LIBRARY_PATH=\$HDF5_HOME/lib:\$LD_LIBRARY_PATH
" > $CONDA_PREFIX/etc/conda/activate.d/env_vars.sh
echo "
     export PATH=\$OLD_PATH
     export LD_LIBRARY_PATH=\$OLD_LD_LIBRARY_PATH
     unset OLD_PATH
     unset OLD_LD_LIBRARY_PATH

     unset OMPI_CC
     unset OMPI_CXX
     unset OMPI_FC
     unset PETSC_DIR
     unset PETSC_ARCH
     unset CGNS_HOME
     unset HDF5_HOME
" > $CONDA_PREFIX/etc/conda/deactivate.d/env_vars.sh
# reload environment

# ########################################
# Compile and Install MACH
# ########################################
# Pleas exchange the following lines in all config.mk files:
# CGNS_INCLUDE_FLAGS=-I$(CGNS_HOME)/include -I$(HDF5_HOME)/include
# CGNS_LINKER_FLAGS=-L$(CGNS_HOME)/lib -lcgns -L$(HDF5_HOME)/lib -lhdf5

# baseclasses
pip install mdolab-baseclasses testflo parameterized

# pySpline
git clone https://github.com/mdolab/pyspline.git
cp pyspline/config/defaults/config.LINUX_GFORTRAN.mk pyspline/config/config.mk
make -C pyspline
pip install pyspline/.

# pyGeo
git clone https://github.com/mdolab/pygeo.git
pip install pygeo/.

# idwarp
git clone https://github.com/mdolab/idwarp.git
cp idwarp/config/defaults/config.LINUX_GFORTRAN_OPENMPI.mk idwarp/config/config.mk
make -C idwarp
pip install idwarp/.

# ADFlow
git clone https://github.com/mdolab/adflow.git
cp adflow/config/defaults/config.LINUX_GFORTRAN.mk adflow/config/config.mk
make -C adflow
pip install adflow/.

# pyOptsparse
git clone https://github.com/mdolab/pyoptsparse.git
pip install pyoptsparse/.[optview]

# pyHyp
git clone https://github.com/mdolab/pyhyp.git
cp pyhyp/config/defaults/config.LINUX_GFORTRAN_OPENMPI.mk pyhyp/config/config.mk
make -C pyhyp
pip intall pyhyp/.

# Multipoint
git clone https://github.com/mdolab/multipoint.git
pip install multipoint/.

# cgnsUtilities
git clone https://github.com/mdolab/cgnsutilities.git
cp cgnsutilities/config/defaults/config.LINUX_GFORTRAN.mk cgnsutilities/config/config.mk
make -C cgnsutilities
pip install cgnsutilities/.


# adflow_util
pip install git+https://github.com/DavidAnderegg/adflow_util.git
