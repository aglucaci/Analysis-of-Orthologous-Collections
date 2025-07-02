#!/bin/bash
#SBATCH --job-name=AOC            # Job name
#SBATCH --output=logs/AOC.out     # Output file (%x=job-name, %j=job ID)
#SBATCH --error=logs/AOC.err      # Error file
#SBATCH --time=72:00:00           # Wall time (hh:mm:ss)
#SBATCH --ntasks=1                # Number of tasks (usually 1 unless MPI)
#SBATCH --cpus-per-task=8         # Number of CPU cores per task
#SBATCH --mem=16G                 # Memory per node

clear

# Banner
echo ""
echo ""
cat <<'EOF'
     █████╗   ██████╗   ██████╗
    ██╔══██╗ ██╔═══██╗ ██╔════╝
    ███████║ ██║   ██║ ██║
    ██╔══██║ ██║   ██║ ██║
    ██║  ██║ ╚██████╔╝ ╚██████╔╝
    ╚═╝  ╚═╝  ╚═════╝   ╚═════╝
EOF
echo ""
echo ""

###############################################################################
# Declares
###############################################################################

#multigeneYAML="config/user-config.yml"
multigeneYAML="user/genes.yml"
configYAML="config/config.yml"

###############################################################################
# Helper Functions
###############################################################################

parse_yaml() {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p" "$1" |
   awk -F"$fs" '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) if (i > indent) delete vname[i];
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) vn=(vn)(vname[i])("_");
         printf("%s%s%s=\"%s\"\n", "'$prefix'", vn, $2, $3);
      }
   }'
}

spinner() {
    local pid=$!
    local delay=0.1
    local spinstr='|/-\'
    tput civis  # Hide cursor

    while kill -0 $pid 2>/dev/null; do
        for ((i=0; i<${#spinstr}; i++)); do
            printf "\r[%c] Working..." "${spinstr:$i:1}"
            sleep $delay
        done
    done

    printf "\r[✓] Done!        \n"
    tput cnorm  # Show cursor
}

###############################################################################
# Main
###############################################################################

eval $(parse_yaml $multigeneYAML)
echo "# ############################################################################# #"
echo ""
echo "[INFO] Starting..."
echo "[INFO] Examining the following genes: $GENES"
#echo "CPU: $resources_cpu"

#echo "# ############################################################################# #"
echo ""
IFS=',' read -ra parts <<< "$GENES"

echo "# ----------------------------------------------------------------------------- #"

# Loop over the parts
for part in "${parts[@]}"; do
    echo ""
    echo "[INFO] Gene: $part"
    
    IFS='_' read -r part1 part2 <<< "$part"

    echo "       Clade: $part1"
    echo "       Gene name: $part2"
    
    nucleotide=$part2"_refseq_transcript.fasta"
    protein=$part2"_refseq_protein.fasta"
    csv=$part2"_orthologs.csv"
    label=$part
    
    echo ""
    echo "[INFO] Updating config YAML file..."
    echo "       $nucleotide"
    echo "       $protein"
    echo "       $csv"
    echo "       $label"
    echo ""
    #echo "# ############################################################################# #"
    echo "# ----------------------------------------------------------------------------- #"

    # Update values using yq
    yq -i -y ".Nucleotide = \"$nucleotide\"" $configYAML
    yq -i -y ".Protein = \"$protein\"" $configYAML
    yq -i -y ".CSV = \"$csv\"" $configYAML
    yq -i -y ".Label = \"$label\"" $configYAML
    
    echo ""
    echo "[INFO] Config YAML updated..."
    echo ""
    
    echo "[INFO] Launching AOC..."
    

    # Simulate long process in background
    (sleep 5) & spinner
    
    cmd="bash scripts/run_AOC_HPC.sh"
    echo $cmd
    eval $cmd
done

###############################################################################
# End of file
###############################################################################

