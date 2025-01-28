# LLM-DRL Data Collection

This repository contains the code and data used for training and evaluating the L4S-LLM model. The goal is to conduct a series of networking experiments to gather data and analyze the results for optimization purposes.

## Directory Structure

- **LLM-DRL Data Collection/**: The main directory for the project, containing all related code and data.
  
  - **iterative_data_collection.sh**: This is the primary script for running the networking experiments. It collects data and executes various tasks in the data collection process.
  
  - **increase_dmesg_size_limit_guide.txt**: A guide for increasing the Kernel Log Storage limit. This is necessary to ensure that the kernel log can store all relevant data during the experiments.
  
  - **data_download_iterative.sh**: This script is responsible for downloading and organizing the experiment results, including kernel logs, into their respective folders.

## Getting Started

### Prerequisites

Before running the scripts, make sure you have the following installed:

- **Linux-based OS**: The scripts are intended to be run on Linux environments.
- **Bash Shell**: Ensure your system has Bash shell installed.
- **Permissions**: You may need superuser permissions to increase the `dmesg` size and to run certain network commands.

### Setting Up Kernel Log Storage

To prevent truncation of kernel logs during experiments, follow the instructions in `increase_dmesg_size_limit_guide.txt` to increase the kernel log storage limit. This is an important step for ensuring that all logs are captured during experimentation.

### Running the Experiment

1. **Collecting Data**: 
   Run the `iterative_data_collection.sh` script to begin the networking experiment. This will collect all necessary data points and kernel logs.

   ```bash
   bash iterative_data_collection.sh
