import pathlib
import yaml
import pandas as pd
import numpy as np
from glob import glob
import os
import sys

# Load configuration file
with open(sys.argv[1]) as f_:
    config = yaml.load(f_, Loader=yaml.FullLoader)


def create_output_dir(output_dir):
    """Ensure the output directory is located within the `results` folder."""
    base_dir = "results"
    if not output_dir.startswith(base_dir):
        output_dir = os.path.join(base_dir, output_dir)
    pathlib.Path(output_dir).mkdir(parents=True, exist_ok=True)
    return output_dir


def create_dataframe_illumina(input_dir):
    """Create a DataFrame for Illumina data (_R1, _R2)."""
    files_r1 = sorted(glob(os.path.join(input_dir, "*_R1.fastq.gz")))
    files_r2 = sorted(glob(os.path.join(input_dir, "*_R2.fastq.gz")))

    # Identify samples
    samples_r1 = {os.path.basename(f).split('_R1')[0] for f in files_r1}
    samples_r2 = {os.path.basename(f).split('_R2')[0] for f in files_r2}
    all_samples = samples_r1 | samples_r2

    # Map files to sample and file types (_R1, _R2)
    file_mapping = {sample: {} for sample in all_samples}
    for f in files_r1:
        sample = os.path.basename(f).split('_R1')[0]
        file_mapping[sample]['_R1'] = f
    for f in files_r2:
        sample = os.path.basename(f).split('_R2')[0]
        file_mapping[sample]['_R2'] = f

    # Check for missing files
    missing_files = []
    for sample, files in file_mapping.items():
        for ftype in ["_R1", "_R2"]:
            if ftype not in files or not os.path.exists(files[ftype]):
                missing_files.append(f"{sample} ({ftype})")

    if missing_files:
        print("Error: The following files are missing for the Illumina data type:")
        print("Existing files:")
        for missing in missing_files:
            print(f"  - {missing}")
        sys.exit(1)

    # Create the DataFrame
    data = []
    for sample, files in file_mapping.items():
        row = {
            "sample": sample,
            "fq1": files.get('_R1', np.nan),
            "fq2": files.get('_R2', np.nan),
            "ONT": np.nan
        }
        data.append(row)

    return pd.DataFrame(data)


def create_dataframe_hybrid(input_dir):
    """Create a DataFrame for Hybrid data (_R1, _R2, _ONT)."""
    files_r1 = sorted(glob(os.path.join(input_dir, "*_R1.fastq.gz")))
    files_r2 = sorted(glob(os.path.join(input_dir, "*_R2.fastq.gz")))
    files_ont = sorted(glob(os.path.join(input_dir, "*_ONT.fastq.gz")))

    # Identify samples
    samples_r1 = {os.path.basename(f).split('_R1')[0] for f in files_r1}
    samples_r2 = {os.path.basename(f).split('_R2')[0] for f in files_r2}
    samples_ont = {os.path.basename(f).split('_ONT')[0] for f in files_ont}
    all_samples = samples_r1 | samples_r2 | samples_ont

    # Map files to sample and file types (_R1, _R2, _ONT)
    file_mapping = {sample: {} for sample in all_samples}
    for f in files_r1:
        sample = os.path.basename(f).split('_R1')[0]
        file_mapping[sample]['_R1'] = f
    for f in files_r2:
        sample = os.path.basename(f).split('_R2')[0]
        file_mapping[sample]['_R2'] = f
    for f in files_ont:
        sample = os.path.basename(f).split('_ONT')[0]
        file_mapping[sample]['_ONT'] = f

    # Check for missing files
    missing_files = []
    for sample, files in file_mapping.items():
        for ftype in ["_R1", "_R2", "_ONT"]:
            if ftype not in files or not os.path.exists(files[ftype]):
                missing_files.append(f"{sample} ({ftype})")

    if missing_files:
        print("Error: The following files are missing for the Hybrid data type:")
        print("Existing files:")
        for missing in missing_files:
            print(f"  - {missing}")
        sys.exit(1)

    # Create the DataFrame
    data = []
    for sample, files in file_mapping.items():
        row = {
            "sample": sample,
            "fq1": files.get('_R1', np.nan),
            "fq2": files.get('_R2', np.nan),
            "ONT": files.get('_ONT', np.nan)
        }
        data.append(row)

    return pd.DataFrame(data)


def create_dataframe_nanopore(input_dir):
    """Create a DataFrame for Nanopore data (_ONT)."""
    # Collect _ONT files
    files_ont = sorted(glob(os.path.join(input_dir, "*_ONT.fastq.gz")))

    # Check if _ONT files are present
    if not files_ont:
        print("Error: No _ONT files found. Please check the filenames in the folder.")
        sys.exit(1)

    # Extract samples from _ONT files
    data = []
    for f in files_ont:
        sample = os.path.basename(f).split('_ONT')[0]
        data.append({"sample": sample, "fq1": np.nan, "fq2": np.nan, "ONT": f})

    return pd.DataFrame(data)


if __name__ == '__main__':
    # Load settings from the config file
    input_dir = config['general']['filename']
    data_type = config['settings']['data_type']
    output_dir = config["general"]["output_dir"]

    # Ensure the output directory is within `results`
    output_dir = create_output_dir(output_dir)

    # Create and validate the DataFrame
    if data_type == "Illumina":
        df = create_dataframe_illumina(input_dir)
    elif data_type == "Hybrid":
        df = create_dataframe_hybrid(input_dir)
    elif data_type == "Nanopore":
        df = create_dataframe_nanopore(input_dir)
    else:
        print(f"Error: Unsupported data type '{data_type}'.")
        sys.exit(1)

    # Save DataFrame
    output_file = os.path.join(output_dir, config["general"]['units'])
    df.to_csv(output_file, sep='\t', index=False)
    print("\nmetassm v1.0.0; Bioinformatics")
    print(df.dropna(how="all", axis=1))
    print("----------")
    print("Create dataframe with sample data...")
    print(f"Save dataframe to: {output_file}\n")
