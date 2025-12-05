## Re-Implementing QuickTree Phylogeny Tools on Pfam Protein Families

*Zeina Ebeid | 
Department of Computer Science, University of Victoria |
Fall 2025*


### Abstract

Neighbour-Joining (NJ) remains widely used for phylogenetic tree construction due to its simplicity and efficiency. QuickTree is a popular implementation that claims speed advantages over traditional tools such as PHYLIP and ClustalW. In this project, I re-implemented the benchmarking pipeline from [Howe et al. (2002)](https://pubmed.ncbi.nlm.nih.gov/12424131/) to test QuickTree’s performance on real Pfam protein families. My implementation automates the execution of each algorithm, distance-matrix generation, and runtime measurement. Although I could not reproduce the scalability claims for large Pfam families due to limited computational resources, QuickTree demonstrated fast sequence processing, supporting the paper’s performance result.

### Introduction

Building phylogenetic trees for large protein families is computationally expensive. Most classical approaches rely on exhaustive distance computations or alignment-heavy steps that scale poorly with sequence count. QuickTree was introduced as an alternative that uses Neighbor-Joining with simplified processes to speed up tree construction.

The original QuickTree paper benchmarks runtime performance against PHYLIP’s neighbor program, ClustalW, and BIONJ, finding significant performance of QuickTree on large Pfam datasets. However, the paper omits key implementation details, including distance-matrix generation and Pfam download procedures, making exact reproduction difficult. In order to work around this, I manually downloaded all Pfam datasets from the [Interpro](https://www.ebi.ac.uk/interpro/) website, unzipped the files, and created a script to convert them to distance matrices. This portion of the implementation was conducted without inspiration from the paper, as they omitted details about data preparation. 

In this project, I reconstructed the benchmarking pipeline and evaluated four tools:
- **QuickTree** (original study focus)
- **PHYLIP neighbor**
- **ClustalW**
- **BioNJ** 

The primary objective was to determine whether QuickTree still offers the fastest construction times when tested with the following hardware environment:
- **OS:** macOS  
- **Shell:** `zsh`  
- **Hardware:** 8 GB RAM (laptop)

### Methods

#### Project Structure

The implementation consists of a structured directory system:

```
project/
│── benchmarks/         # Combined runtime logs (timings_small.csv, timings_large.csv)
│── data/               # Pfam datasets, distance matrices (small + large)
│── external_tools/
│     ├── quicktree/    # run_quicktree_small.sh, run_quicktree_large.sh
│     ├── clustalw/
│     ├── phylip/
│     └── bionj/
│── results/
│── poster.png        
│── report.md           # This document
```


#### Dataset Preparation

Two Pfam datasets were used:
```
Dataset         Size Criteria	  Families	  
-----------  ------------------  ----------  
Pfam-Small	  ≤ 500 sequences	     32	 
Pfam-Large	 500–3000 sequences	     12

```
Unlike the original study, which did not describe dataset collection method, I downloaded Pfam seed alignments manually and generated PHYLIP distance matrices using a custom script. Each tool ran the same matrices to ensure identical input data across algorithms.

#### Benchmarking Pipeline

Each tool was executed using `./externaltools/run_<tool>_<size>.sh`

For example, to run QuickTree using the small Pfam dataset, use `./externaltools/run_quicktree_small.sh`

#### Time Plot Preperation

Timings were converted to milliseconds (ms) and appended to `benchmarks/timings_<size>.csv` depending on whether the small or large Pfam datasets were used. 

All tests ran were appending to the csv files in the format `dataset,n_seq,tool,real_ms`. This format allows direct plotting and comparison in RStudio. 

### Results

Timings for both the small and large Pfam datasets were visualized using RStudio. I visualized my plots with different colours for each algorithm to make differentiating the results more simple. Also, due to resource limits, the paper's claimed scalability could not be fully reproduced. 

Overall, timing benchmarks were imported into RStudio and plotted to visualize runtime performance across algorithms and dataset sizes.

The following graphs are a comparison of the plots I produced, compared to the original paper's plots.  


**My plots:**

<img width="45%" height="45%" alt="Rplot-Small" src="https://github.com/user-attachments/assets/f32e98d4-6548-4901-b504-4f0ee236f5cf" />

<img width="45%" height="45%" alt="Rplot_large" src="https://github.com/user-attachments/assets/deda92ac-822c-4016-a7b9-2a898a57a4e7" />


**Original paper's plots:**

<img width="45%" height="45%" alt="Screenshot 2025-12-04 at 10 38 49 PM" src="https://github.com/user-attachments/assets/eec8d421-5f79-4699-9f5d-5218a9384063" />

<img width="45%" height="45%" alt="Screenshot 2025-12-04 at 10 39 17 PM" src="https://github.com/user-attachments/assets/ba9a1c32-e9a9-4dcf-b364-6b424be2fa96" />


### Comparison with Original Paper

The performance plots I generated somewhat align with the visual trends reported in Howe et al. (2002). In the original paper, QuickTree demonstrated a clear time advantage over the other tools such as ClustalW and PHYLIP as the number of sequences increased. My graphs exhibit a similar pattern: QuickTree (purple line) completed tree construction in less time across Pfam families of varying sizes, with some exceptions. This different is more apparent in the large Pfam dataset, as opposed to the small Pfam dataset. 

However, the magnitude of the improvements was less dramatic in my results. The published figures showed exponential difference in runtime between QuickTree and other algorithms for larger datasets, my plots showed a more mild difference, particularly in the Pfam-large tests. This difference is likely due to hardware constraints and the comparatively smaller dataset scale used in my environment, which limited QuickTree’s ability to demonstrate the extreme scalability highlighted in the original study.

Despite these differences, both sets of graphs support the same qualitative conclusion, that the QuickTree implementation is faster than ClustalW, PHYLIP, and BIONJ when constructing neighbor-joining trees.

### Conclusion

This project reconstructed the QuickTree benchmarking environment and demonstrated better performance relative to other tools. Although QuickTree’s scalability could not be replicated on my hardware, the observed trends support the original paper's conclusion: QuickTree provides speed improvements for protein-family phylogenetic tree construction. Similar to the authors, I was unable to confirm whether QuickTree improves accuracy, as this was beyond the scope of the original study.


### Reference

Howe, K., Bateman, A., & Durbin, R. (2002). QuickTree: Building Huge Neighbour-Joining Trees of Protein Sequences. Bioinformatics, 18(11), 1546–1547.

### Appendix

All scripts, timing logs, Pfam metadata, and trees generated during this study are available in this GitHub repository. 
