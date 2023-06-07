#!/usr/bin/env bash
set -x
echo PYTHONPATH=$PYTHONPATH
pip install --upgrade pip
#conda install -y setuptools
#conda install -y numpy
#conda install -y sklearn
#conda install -y scipy
#conda install -y tqdm
#conda create --name h2o h2o -y
#conda create --name tensorflow tensorflow -y
#conda create --name pandas pandas -y

# we hit a bug so we have to downgrade components to make things work properly
# bug I logged: https://github.com/spyder-ide/spyder/issues/7084
conda create --name spyder spyder -y
source activate spyder
pip install tornado==4.5.3
pip install jupyter_client==5.2.2
# workaround pour autre bug:
# source: https://github.com/spyder-ide/spyder/issues/3226
conda install pyopengl
source deactivate
