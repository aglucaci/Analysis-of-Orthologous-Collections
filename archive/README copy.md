# Analysis of Orthologous Collections (AOC)

# Aim

This repository offers an Snakemake workflow for investigating the molecular evolution of protein-coding genes. AOC extends core functionality by integrating HyPhy-based selection analyses, taxonomic assignment via NCBI, and phylogenetic tree annotation. These features enable comparative analyses of selective pressures across distinct evolutionary lineages. The software is currently designed to use data from the NCBI Orthologs database (https://ncbiinsights.ncbi.nlm.nih.gov/2019/04/24/searching-for-orthologous-genes-at-ncbi/)).

# Contents of the repository

# Usage

## Installation and dependencies
This application is currently designed to run in an HPC environment due to the computational cost of selection analyse.

There is an assumption that the freely available Anaconda software is installed on your machine.

You will also need to download the standalone hyphy-analyses repository (https://github.com/veg/hyphy-analyses). Make sure to modify the config.yml file to point to the correct directory on your system

### To install -- Steps necessary to complete before running
1. `git clone https://github.com/aglucaci/Analysis-of-Orthologous-Collections.git AOC`
2. `cd AOC`
3. `conda env create -f config/environment.yml`. This will create a virtual environment called (AOC) with the necessary dependencies.
    *NOTE* For those with arm64 CPU architecures (Apple M1/M2), compatibility errors may arise during installation with conda, in order to circumvent this issue try this command before creating the conda environment `conda config --env --set subdir osx-64`
4. At this point, run `conda activate AOC` and your environment will be ready to go.

## Data retrieval via NCBI Orthologs
Here, we rely on the NCBI Ortholog database. For example, if we are interested in the TP53 gene: https://www.ncbi.nlm.nih.gov/gene/7157/ortholog/?scope=117570&term=TP53

Download all information: Tabular data, RefSeq Transcripts, and RefSeq Protein. 

This is typically done as one gene per species, but all transcripts per species is also available.

## Pipeline

**Step 1.** Codon-aware alignment (MACSE2) from protein and gene transcript files \
**Step 2.** Recombination detection (via HyPhy GARD) \
**Step 3.** Tree inference (ML Tree inference: IQ-TREE). \
**Step 4.** Selection analysis including (MEME, FEL, FUBAR, BUSTED Model testing, MEME, aBSREL, SLAC, BGM, FMM, etc) \
**Step 4.** Lineage assignment (NCBI via ete3) and phylogenetic tree annotation (custom script) \
**Step 5.** Selection analyses on lineages (RELAX, CFEL)
**Step 6.** Summarize results

## Further explaination of the selection analysis methods

| Method            | Full Name                                 | Purpose                                                                                     | Scale of Analysis               | Notes                                                                                   |
|-------------------|--------------------------------------------|---------------------------------------------------------------------------------------------|----------------------------------|------------------------------------------------------------------------------------------|
| FEL               | Fixed Effects Likelihood                   | Detects pervasive (consistent across branches) selection at individual sites               | Site-level, pervasive            | Estimates dN and dS at each site using ML; more accurate but slower than SLAC.          |
| SLAC              | Single Likelihood Ancestor Counting        | Rapid, conservative detection of pervasive selection at sites                              | Site-level, pervasive            | Faster, approximate; uses reconstructed ancestral sequences to count substitutions.     |
| MEME              | Mixed Effects Model of Evolution           | Detects episodic (branch-specific) positive selection at individual sites                  | Site-level, episodic             | Can identify sites under selection in a subset of branches.                             |
| FUBAR             | Fast Unconstrained Bayesian AppRoximation | Detects pervasive selection using Bayesian inference                                       | Site-level, pervasive            | Fast, efficient, and good for large datasets; assumes selection is constant over time.  |
| aBSREL            | Adaptive Branch-Site REL                   | Detects episodic diversifying selection on individual branches                             | Branch-level, episodic           | Fits different selection models to each branch adaptively.                              |
| BUSTED            | Branch-site Unrestricted Test for Episodic Diversification | Tests if *any* site on *any* branch has experienced episodic positive selection | Gene-wide, branch-site            | Good for gene-wide screening; doesn’t localize selection to specific sites or branches. |
| Model Testing     | -                                          | Compares nested codon models to test for selection or model fit                            | Gene-level                        | Used to determine the best-fitting model (e.g., with or without selection).             |
| BGM               | Bayesian Graphical Models                  | Detects co-evolving site pairs                                                              | Site-pair level                   | Reveals dependencies or correlations among sites across the alignment.                  |
| FMM               | Finite Mixture Models                      | Clusters sites into discrete selection regimes                                              | Site-level, across categories     | Models heterogeneous selection pressures across codon sites.                            |


## Example dataset and test results

### Preparation
As an example of the AOC pipeline, we explore the evolutionary history of the Primate ACE2 protein. Data was accessed from NCBI via the Ortholog data base at https://www.ncbi.nlm.nih.gov/gene/59272/ortholog/?scope=9443&term=ACE2. Where, we downloaded FASTA files with RefSeq Transcripts and RefSeq Proteins (one sequence per specices) and metadata in tabular form (CSV))

This data was placed in the `data` folder using the `PrimateACE2` tag to create a `PrimateACE2` folder.  
Our data folder structure should look like this:

```
── data
│   ├── Primate_ACE2
│   |   ├── ACE2_refseq_transcript.fasta
│   |   ├── ACE2_refseq_protein.fasta
│   |   ├── ACE2_orthologs.csv
```

We will ammend YAML formatted configuration file called `config.yml` file where the `Label` variable will also be `PrimateACE2`. We will also modify the `Nucleotide`, `Protein`, and `CSV` variables with the names of our downloaded data files.

Our `config.yml` file should look like this:

```
# User settings for data files and gene label

# Settings for ... Primate ACE2
Nucleotide: ACE2_refseq_transcript.fasta
Protein: ACE2_refseq_protein.fasta
CSV: ACE2_orthologs.csv
Label: PrimateACE2

# User settings for NCBI Entrez
EMAIL: "aoc-user@example.com"
```

We will ammend our cluster.json file to correspond to the number of available compute power for our system.

```
{"__default__": 
  {
  "cluster" : "qsub",
  "nodes": 1,
  "ppn": 8,
  "name": "cpu"
}}
```

Most important, if you are running locally, modify the `ppn` variable, otherwise for HPC deployment check with your system administration for requirements or use your best judgement.

We can now execute our program with `bash run_AOC_Local.sh`

This command performs the entire analysis.

### Results
The following are JSON files produced by HyPhy analyses. These can be visualized by the appropriate module from HyPhy Vision (http://vision.hyphy.org/). Analysis file names contain the method used (SLAC, FEL, PRIME, FADE, MEME, CFEL, etc), and if appropriate -- the set of branches to which the analysis was applied.

```
── results/PrimateACE2
│   ├── PrimateACE2_codons.SA.fasta.FEL.json
│   ├── PrimateACE2_codons.SA.fasta.FUBAR.json
│   ├── PrimateACE2_codons.SA.fasta.MEME.json
│   ├── PrimateACE2_codons.SA.fasta.ABSREL.json
│   ├── PrimateACE2_codons.SA.fasta.SLAC.json
│   ├── PrimateACE2_codons.SA.fasta.BGM.json
│   ├── PrimateACE2_codons.SA.fasta.PRIME.json
│   ├── PrimateACE2_codons.SA.fasta.FMM.json
│   ├── PrimateACE2_codons.SA.fasta.ABSREL.json
|   ├── PrimateACE2_codons.SA.fasta.ABSRELS.json
│   ├── PrimateACE2_codons.SA.fasta.BUSTEDSMH.json
│   ├── PrimateACE2_codons.SA.fasta.BUSTED.json
│   ├── PrimateACE2_codons.SA.fasta.BUSTEDMH.json
│   ├── PrimateACE2_codons.SA.fasta.BUSTEDS.json
│   ├── PrimateACE2.aoc.executiveSummary.csv
│   ├── Visualizations/
│   ├── │   ├── PrimateACE2.1.codon.fas.FEL.json.FEL.png
│   ├── │   ├── PrimateACE2.1.codon.fas.FEL.json.FEL.svg
│   ├── │   ├── PrimateACE2.1.codon.fas.FEL.json.FEL.figureLegend
│   ├── │   ├── PrimateACE2.1.codon.fas.FEL.json.FEL.csv
│   ├── │   ├── ... these continue for MEME and BGM
│   ├── │   ├── ... other visualizations are available on HyPhy Vision.
│   ├── Tables /
│   ├── │   ├──
│   ├── │   ├──
│   ├── │   ├──
│   ├── │   ├──
```

### Executive summary 

In order to make results easily interpretable - we provide a summary spreadsheet for each analysis (Rows), and for each recombination-free file (columns).

|FIELD1      |1                      |2                      |3                      |4                      |
|------------|-----------------------|-----------------------|-----------------------|-----------------------|
|Filename    |PrimateACE2.1.codon.fas|PrimateACE2.2.codon.fas|PrimateACE2.3.codon.fas|PrimateACE2.4.codon.fas|
|Seqs        |31                     |31                     |31                     |31                     |
|Sites       |419                    |234                    |44                     |300                    |
|FitMG94     |N/A                    |N/A                    |N/A                    |N/A                    |
|BUSTED[S]   |0.04772686506595974    |0.5                    |0.498342357346389      |0.2872065056121928     |
|BUSTED[S]+MH|0.05354633995163294    |0.5                    |0.5                    |0.4492374314471226     |
|FEL[+]      |6                      |1                      |0                      |3                      |
|FEL[-]      |66                     |44                     |4                      |36                     |
|FUBAR[+]    |5                      |1                      |1                      |2                      |
|FUBAR[-]    |35                     |29                     |2                      |15                     |
|SLAC[+]     |0                      |0                      |0                      |0                      |
|SLAC[-]     |0                      |0                      |0                      |0                      |
|MEME        |11                     |1                      |1                      |11                     |
|BGM         |10                     |5                      |1                      |5                      |
|aBSREL      |1                      |0                      |1                      |0                      |
|FMM[TH]     |0.4091059976738896     |0.5938634883238164     |0.6307068479526645     |0.3115028373429701     |
|FMM[DH]     |0.7218940918363086     |0.6477264324528813     |0.9861745455939988     |0.05874773670413536    |
|RELAX       |0.3694805831206783     |0.5508425231243457     |0.04165610895306981    |0.2446019676208168     |
|CFEL        |0                      |0                      |0                      |0                      |

<ol>
  <li>We report omega values for each recombination-free segments for FitMG94.</li>
  <li>LRT p-values are reported for BUSTED[S], FMM[TH], FMM[DH], and RELAX. </li>
  <li>aBSREL reports the number of branches under selection. </li>
  <li>The rest of the columns report the number of statistically significant codon sites under selection.</li>
</ol>

### Visualizations 

For FEL, which reports codon-site specific dN/dS values.
<table>
  <tr>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.1.codon.fas.FEL.json.FEL.png" width="300" height="200"></td>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.2.codon.fas.FEL.json.FEL.png" width="300" height="200"></td>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.3.codon.fas.FEL.json.FEL.png" width="300" height="200"></td>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.4.codon.fas.FEL.json.FEL.png" width="300" height="200"></td>
  </tr>
</table>

For MEME, which reports adaptively evolving codon-site specific dN/dS values, and is a more sensensitive method.
<table>
  <tr>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.1.codon.fas.MEME.json.MEME.png" width="300" height="200"></td>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.2.codon.fas.MEME.json.MEME.png" width="300" height="200"></td>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.3.codon.fas.MEME.json.MEME.png" width="300" height="200"></td>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.4.codon.fas.MEME.json.MEME.png" width="300" height="200"></td>
  </tr>
</table>

For BGM, which detects co-evolving codon sites.
<table>
  <tr>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.1.codon.fas.BGM.json.BGM.png" width="600" height="200"></td>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.2.codon.fas.BGM.json.BGM.png" width="600" height="200"></td>
  </tr>
</table>

<table>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.3.codon.fas.BGM.json.BGM.png" width="600" height="200"></td>
    <td><img src="https://raw.githubusercontent.com/aglucaci/Analysis-of-Orthologous-Collections/refs/heads/main/results/PrimateACE2/Visualizations/PrimateACE2.4.codon.fas.BGM.json.BGM.png" width="600" height="200"></td>
  </tr>
</table>

### Additional visualizations and statistics are available for each HyPhy JSON file at http://vision.hyphy.org/

## Cleanup and miscellaneous commands

### Removing the AOC environment from conda

To remove the AOC environment from you system use: `conda env remove --name AOC`

### Starting a tmux session for AOC

Due to the runtime needs of the workflow it may be useful to use a terminal multiplexer like 'tmux' in order to keep jobs running. `tmux new -s AOC `
