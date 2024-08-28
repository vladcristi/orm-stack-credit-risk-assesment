## Copyright © 2024, Oracle and/or its affiliates. 
## All rights reserved. The Universal Permissive License (UPL), Version 1.0 as shown at http://oss.oracle.com/licenses/upl


#!/bin/bash
echo "running cloudinit.sh script"

dnf install -y dnf-utils zip unzip gcc

# Install needed packages
echo "PYTHON packages"
dnf -y install oraclelinux-developer-release-el8
dnf module -y install python39
alternatives --set python3 /usr/bin/python3.9
python3 -m pip install jupyter gradio
python3 -m pip install --upgrade pip wheel oci
python3 -m pip install --upgrade setuptools
python3 -m pip install oci-cli
python3 -m pip install python-multipart
python3 -m pip install pypdf
python3 -m pip install six

conda install -c conda-forge -y --force-reinstall python==3.11.5
python3 -m pip install --extra-index-url https://pypi.nvidia.com cudf-cu12
python3 -m pip install --extra-index-url https://pypi.nvidia.com cuml-cu12
python3 -m pip install --extra-index-url https://pypi.nvidia.com cugraph-cu12
python3 -m pip install numpy
python3 -m pip install pandas
python3 -m pip install seaborn
python3 -m pip install cudf
python3 -m pip install sklearn
python3 -m pip install seaborn
python3 -m pip install oci
python3 -m pip install ocifs
python3 -m pip install xgboost
python3 -m pip install shap
python3 -m pip install scikit-learn
python3 -m pip install --upgrade torch
python3 -m pip install imblearn
python3 -m pip install nvtabular
python3 -m pip install --extra-index-url https://pypi.nvidia.com cugraph-cu12
python3 -m pip install --extra-index-url https://pypi.nvidia.com cuxfilter-cu12


#firewall-cmd --permanent --add-port=8888/tcp
#firewall-cmd --permanent --add-port=8080/tcp
#firewall-cmd --reload