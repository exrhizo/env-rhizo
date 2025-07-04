export ENV_NAME=${1:-lu}
export DEFAULT_LOUIE_DIR=/Users/exrhizo/Projects/graphistry/louie

if [ -f "graphistrygpt/conda-lock.yml" ]; then
    export CONDA_LOCK_FILE="$(pwd)/graphistrygpt/conda-lock.yml"
else
    export CONDA_LOCK_FILE=$DEFAULT_LOUIE_DIR/graphistrygpt/conda-lock.yml
fi


conda remove --name $ENV_NAME --all -y
conda-lock install -n $ENV_NAME --validate-platform $CONDA_LOCK_FILE

conda activate $ENV_NAME
conda install py-spy conda-lock ipykernel -y