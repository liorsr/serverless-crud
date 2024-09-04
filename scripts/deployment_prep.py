"""
Prepare relevant files for deployment
"""

import os
import shutil
import zipfile


def zip_lambda_code(src_dir: str, dist_dir: str, zip_name: str):
    """
    Zip contents of source directory and save to destination.

    Args:
        src_dir: Path to source dir.
        dist_dir: Path to destination dir.
        zip_name: Name of zip file.

    """
    zip_path = os.path.join(dist_dir, zip_name)

    with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zipf:
        for root, _, files in os.walk(src_dir):
            # Add files to archive
            for file in files:
                file_path = os.path.join(root, file)
                archive_name = os.path.relpath(file_path, src_dir)
                zipf.write(file_path, archive_name)


def copy_html_template(src_file: str, dest_file: str):
    """
    Copy HTML template file to destination.

    Args:
        src_file: Path to source.
        dest_file: Path to destination.

    """
    shutil.copy(src_file, dest_file)


def prep_deploymment():
    """
    Prepare files for deployment.
    """
    # Get the base dir
    BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

    SRC_LAMBDA_DIR = os.path.join(BASE_DIR, "src", "lambda")
    DIST_DIR = os.path.join(BASE_DIR, "dist")
    ZIP_NAME = "crud_lambda_function.zip"
    HTML_SRC_FILE = os.path.join(BASE_DIR, "src", "site", "index.html")
    HTML_DEST_FILE = os.path.join(DIST_DIR, "index.html.template")

    # Create dist directory if it doesn't exist
    os.makedirs(DIST_DIR, exist_ok=True)

    # Zip lambda source code
    zip_lambda_code(SRC_LAMBDA_DIR, DIST_DIR, ZIP_NAME)
    print(f"Zipped '{SRC_LAMBDA_DIR}' into '{DIST_DIR}/{ZIP_NAME}'")

    # Copy HTML template
    copy_html_template(HTML_SRC_FILE, HTML_DEST_FILE)
    print(f"Copied '{HTML_SRC_FILE}' to '{HTML_DEST_FILE}'")


if __name__ == "__main__":
    prep_deploymment()
