from pathlib import Path
import os

DEFAULTS_DIR = Path(
    r'C:\Users\mkcor\AppData\Roaming\MetaQuotes\Terminal\49CDDEAA95A409ED22BD2287BB67CB9C\MQL5\Experts\My_Experts\NNFX\Entry_testing\default\indicators')
OPTIMISE_DIR = Path(
    r'C:\Users\mkcor\AppData\Roaming\MetaQuotes\Terminal\49CDDEAA95A409ED22BD2287BB67CB9C\MQL5\Experts\My_Experts\NNFX\Entry_testing\optimise\indicators')
MASTER_CONFIG_DIR = Path(
    r'C:\Users\mkcor\AppData\Roaming\MetaQuotes\Terminal\49CDDEAA95A409ED22BD2287BB67CB9C\MQL5\Experts\My_Experts\NNFX\Entry_testing\optimise\master_config_files')


def pre_process_checks():
    """
    Pre-process check that verifies the presence of valid indicator files and generates necessary configuration templates.

    This function:
    - Checks if the indicator files in the default and optimizable directories have the correct suffixes.
    - Creates master configuration template files if required in the master config directory.
    """
    print("---------- Checking: default/indicators ---------------")
    check_indicators_suffix(DEFAULTS_DIR)

    print("---------- Checking: optimise/indicators --------------")
    check_indicators_suffix(OPTIMISE_DIR)

    print("---------- Checking: optimise/master_config_files -----")
    create_cp_templates(OPTIMISE_DIR, MASTER_CONFIG_DIR)


def check_indicators_suffix(dir):
    """
    Verifies if the indicator files in the specified directory have valid suffixes.

    Args:
        dir (Path): The directory containing the indicator files.

    This function checks that all .mq5 and .ex5 files have one of the following suffixes:
    - "clc", "cbc", "clx", "hcc", "hlx", "lcc", "0lx", "2lx"

    If a file does not have one of these suffixes, a warning is printed.
    """
    suffex_list = ["clc", "cbc", "clx", "hcc", "hlx", "lcc", "0lx", "2lx"]
    for file in os.listdir(dir):
        filename, file_extension = os.path.splitext(file)

        if file_extension in [".mq5", ".ex5"]:
            file_suffix = filename[-3:]
            if file_suffix not in suffex_list:
                print(f"{file} - INCORRECT FILE SUFFIX")
    print("Complete.")


def create_cp_templates(opt_dir, master_config_dir):
    """
    Creates master configuration template files in the specified master config directory.

    Args:
        opt_dir (Path): The directory containing the optimizable indicator files.
        master_config_dir (Path): The directory where the master configuration files should be created.

    This function generates a new template file for each .ex5 file in the optimizable directory,
    creating a template file with the same name in the master config directory. If a corresponding
    .ini file already exists, it skips the creation.
    """
    for file in os.listdir(opt_dir):
        filename, file_extension = os.path.splitext(file)
        if file_extension == ".ex5":
            template_file = master_config_dir / filename
            ini_file = master_config_dir / f"{filename}.ini"

            if ini_file.exists() and template_file.exists():
                template_file.unlink()  # Remove existing template file if it exists
            else:
                with open(template_file, 'w') as f:
                    f.write("Template content here")  # Add content to the template
                print(f"Master config for required - {filename}")
    print("Complete.")


if __name__ == "__main__":
    pre_process_checks()
