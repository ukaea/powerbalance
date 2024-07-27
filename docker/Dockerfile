FROM openmodelica/openmodelica:v1.21.0-ompython
ARG msl_version=4.0.0
RUN echo "installPackage(Modelica, \"${msl_version}\");"  >> install.mos
RUN omc install.mos
RUN rm install.mos
RUN apt update
RUN apt install -y git
RUN pip install git+https://github.com/ukaea/powerbalance.git
RUN powerbalance generate-profiles
ENTRYPOINT [ "powerbalance" ]
