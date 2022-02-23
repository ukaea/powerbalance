# Configuring a Run
Properties for a Power Balance Models (PBM) are set via configuration files which are in the TOML format. These are parsed as inputs and used to specify model selection and parameter values. 

??? info "TOML files"
    TOML files can be commented! Do take advantage of this when writing your PBM configs for future reference by yourself or others. For more information on how to write TOML files see the documentation [site](https://toml.io/en/).

!!! warning "Configuration priority"
    If an option is specified within the configuration file AND on the command line interface, the latter is prioritised.