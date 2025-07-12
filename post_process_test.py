import pandas as pd
from pathlib import Path
import logging
from xml.sax import ContentHandler, parse
from typing import List, Tuple

from pandas import DataFrame

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')


class PostProcessData:
    """
    Class for post-processing and combining results from multiple indicator testing files.
    """

    def __init__(self, results_dir: Path, print_outputs: bool = True, output_file: str = '1_combined_results.csv'):
        """
        Initializes the PostProcessData class with the provided directory and output file.

        Args:
            results_dir (Path): The directory where the result files are located.
            print_outputs (bool): Whether to print the final output.
            output_file (str): The name of the combined output CSV file.
        """
        self.results_dir = results_dir
        self.print_outputs = print_outputs
        self.output_file = output_file
        self.run()

    def run(self):
        """
        Processes result files, calculates statistics, and saves the combined results.
        """
        df_combined = self.process_results_files()

        if df_combined is not None:
            # Save the combined results as a CSV file
            output_path = self.results_dir / self.output_file
            df_combined.to_csv(output_path, index=False)
            self.combine_opt_results()

            if self.print_outputs:
                print(df_combined)
            else:
                logging.info("Results processing complete.")
        else:
            logging.warning("No valid results to process.")

    def process_results_files(self):
        """
        Processes each indicator result file (ins.xml and out.xml) and computes the statistics.

        Returns:
            pd.DataFrame: Combined results DataFrame.
        """
        df_combined = []
        failed_post_process_list = []

        for file in self.results_dir.iterdir():
            if file.suffix == ".xml" and file.name.endswith("ins.xml"):
                file_prefix = file.stem[:-4]  # Remove '_ins' suffix
                try:
                    df_combined.append(self.process_indicator_file(file_prefix))
                except Exception as e:
                    failed_post_process_list.append(file_prefix)
                    logging.error(f"Failed to process {file_prefix}: {e}")

        # Return combined DataFrame
        if df_combined:
            return pd.DataFrame(df_combined)
        else:
            return

    def process_indicator_file(self, file_prefix: str) -> dict:
        """
        Processes a pair of `ins.xml` and `out.xml` files for an indicator, calculates statistics,
        and returns a dictionary of the results.

        Args:
            file_prefix (str): The base name of the indicator files (without extensions).

        Returns:
            dict: Dictionary of indicator statistics.
        """
        # Load data from XML files
        result_in, p_fac_in, trades_in = self.load_xml_data(file_prefix, "ins")
        result_out, p_fac_out, trades_out = self.load_xml_data(file_prefix, "out")

        # Calculate result statistics
        result_mean = (result_in + result_out) / 2
        pc_result = self.calc_percent_diff(result_in, result_out)
        pc_p_fac = self.calc_percent_diff(p_fac_in, p_fac_out)
        pc_trades = self.calc_percent_diff(trades_in, trades_out)

        # Return a dictionary with computed data
        return {
            'Indicator': file_prefix,
            'R_ins': result_in,
            'R_outs': result_out,
            'R_dif': pc_result,
            'R_mean': result_mean,
            'P_fac_in': p_fac_in,
            'P_fac_out': p_fac_out,
            'P_fac_dif': pc_p_fac,
            'trades_in': trades_in,
            'trades_out': trades_out,
            'trades_dif': pc_trades
        }

    def load_xml_data(self, file_prefix: str, file_type: str):
        """
        Loads data from an XML file (either 'ins' or 'out'), and extracts the result, profit factor, and trades.

        Args:
            file_prefix (str): The prefix of the file (without extension).
            file_type (str): The type of the file ('ins' or 'out').

        Returns:
            tuple: Contains result, profit factor, and trades values as floats.
        """
        try:
            df = self.load_data_from_xml(f"{file_prefix}_{file_type}.xml")
            return float(df["Result"][0]), float(df["Profit Factor"][0]), float(df["Trades"][0])
        except Exception as e:
            logging.error(f"Error loading {file_prefix}_{file_type}.xml: {e}")
            return

    @staticmethod
    def load_data_from_xml(file: str) -> pd.DataFrame:
        """
        Loads data from an XML file and converts it into a Pandas DataFrame.

        Args:
            file (str): The name of the XML file to load.

        Returns:
            pd.DataFrame: Data extracted from the XML file.
        """
        excel_handler = ExcelHandler()
        parse(file, excel_handler)
        df = pd.DataFrame(excel_handler.tables[0][1:], columns=excel_handler.tables[0][0])
        return df

    @staticmethod
    def calc_percent_diff(in_sample: float, out_sample: float) -> float:
        """
        Calculates the percentage difference between two values.

        Args:
            in_sample (float): The "in-sample" value.
            out_sample (float): The "out-sample" value.

        Returns:
            float: The percentage difference between the two values.
        """
        try:
            return round(abs(in_sample - out_sample) / out_sample * 100.0, 2)
        except ZeroDivisionError:
            return 0.0

    def combine_opt_results(self):
        """
        Combines all 'opt_results.txt' files in the results directory into one combined file.
        """
        combined_file_path = self.results_dir / "2_combined_opt_results.txt"
        if combined_file_path.exists():
            combined_file_path.unlink()

        opt_results_list = [file for file in self.results_dir.iterdir() if
                            file.suffix == ".txt" and "opt_results" in file.name]
        new_lines = []
        for file_path in opt_results_list:
            new_lines.append(file_path.read_text())
            new_lines.append("\n\n")

        combined_file_path.write_text("".join(new_lines))


class ExcelHandler(ContentHandler):
    """
    Custom handler to parse XML files and extract table data.
    """

    def __init__(self):
        self.rows = None
        self.cells = None
        self.chars = []
        self.tables = []

    def characters(self, content: str):
        """
        Collects characters in XML elements.
        """
        self.chars.append(content)

    def start_element(self, name: str, attrs):
        """
        Handle the start of XML elements.
        """
        if name == "Table":
            self.rows = []
        elif name == "Row":
            self.cells = []
        elif name == "Data":
            self.chars = []

    def end_element(self, name: str):
        """
        Handle the end of XML elements.
        """
        if name == "Table":
            self.tables.append(self.rows)
        elif name == "Row":
            self.rows.append(self.cells)
        elif name == "Data":
            self.cells.append("".join(self.chars))


if __name__ == "__main__":
    # Example usage with a results directory path
    post_processor = PostProcessData(Path(r'path_to_results'))
