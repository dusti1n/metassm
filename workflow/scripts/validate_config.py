import yaml
import sys
import os

# Correctly formatted assembler names
FORMATTED_ASSEMBLERS = {
    "flye": "Flye",
    "canu": "Canu",
    "shasta": "Shasta",
    "wtdbg2": "WTDBG2",
    "masurca": "MaSuRCA",
    "hifasm": "Hifiasm",
    "spades": "SPAdes",
    "megahit": "MEGAHIT",
    "abyss": "ABySS"
}

def format_assembler_name(assembler):
    # Returns the correctly formatted name of the assembler.
    return FORMATTED_ASSEMBLERS.get(assembler, assembler.capitalize())

# Loads the configuration file and checks if the selected assemblers are valid.
def validate_assembler():
    # Path to 'config.yaml'
    base_dir = os.path.dirname(os.path.dirname(os.path.dirname(__file__)))
    config_path = os.path.join(base_dir, "config", "config.yaml")

    # Check if the file exists
    if not os.path.exists(config_path):
        print(f"ERROR: Configuration file '{config_path}' not found.")
        sys.exit(1)

    # Load the 'config.yaml'
    with open(config_path, "r") as file:
        config = yaml.safe_load(file)

    # Allowed assemblers for each data type
    assembler_options = {
        "Illumina": {"spades", "megahit", "abyss", "masurca"},
        "Nanopore": {"flye", "canu", "shasta", "wtdbg2"},
        "Hybrid": {"flye", "canu", "spades", "hifasm"}
    }

    # Check if the data type is defined
    if "settings" not in config or "data_type" not in config["settings"]:
        print("ERROR: 'data_type' is missing in 'config.yaml'. Allowed values: Illumina, Nanopore, Hybrid.")
        sys.exit(1)

    selected_data_type = config["settings"]["data_type"]
    if selected_data_type not in assembler_options:
        print(f"ERROR: '{selected_data_type}' is not a valid data type. Allowed values: Illumina, Nanopore, Hybrid.")
        sys.exit(1)

    valid_assemblers = assembler_options[selected_data_type]

    # List of enabled assemblers
    selected_assemblers = [
        asm for asm in config.get("assembler", {}) if config["assembler"][asm].get("status", False)
    ]

    # Minimum and maximum number of allowed assemblers
    MIN_ASSEMBLERS = 1
    MAX_ASSEMBLERS = 4

    # Check if the number of selected assemblers is within the allowed range
    if len(selected_assemblers) < MIN_ASSEMBLERS:
        print(f"ERROR: At least {MIN_ASSEMBLERS} assembler(s) are required for {selected_data_type}. Found: {len(selected_assemblers)}.")
        sys.exit(1)

    if len(selected_assemblers) > MAX_ASSEMBLERS:
        print(f"ERROR: A maximum of {MAX_ASSEMBLERS} assemblers are allowed for {selected_data_type}. Found: {len(selected_assemblers)}.")
        sys.exit(1)

    # Check if all selected assemblers are allowed
    invalid_assemblers = [asm for asm in selected_assemblers if asm not in valid_assemblers]
    if invalid_assemblers:
        formatted_invalid = ", ".join(format_assembler_name(asm) for asm in invalid_assemblers)
        formatted_valid = ", ".join(format_assembler_name(asm) for asm in valid_assemblers)
        print(f"ERROR: The following assemblers are not allowed for {selected_data_type}: {formatted_invalid}.")
        print(f"Allowed assemblers for {selected_data_type}: {formatted_valid}.")
        sys.exit(1)
