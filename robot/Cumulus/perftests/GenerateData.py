from pathlib import Path

from snowfakery.cli import generate_cli


class GenerateData(object):
    ROBOT_LIBRARY_SCOPE = "GLOBAL"
    ROBOT_LIBRARY_VERSION = 1.0

    def generate_data(self, recipe, num_records, num_records_tablename, outfile):
        if Path(outfile).exists():
            Path(outfile).unlink()
        generate_cli.callback(
            recipe,
            target_number=(num_records_tablename, int(num_records)),
            dburls=[f"sqlite:///{outfile}"],
        )
