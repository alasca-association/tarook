# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html
import os
import runpy
import sys
sys.path.insert(0, os.path.join(os.getcwd(), "../../"))

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'yaook/k8s OpRef'
copyright = '2020-2022, The Yaook authors'
author = 'The Yaook authors'
release = 'latest'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    "myst_parser",
    'sphinx_rtd_theme',
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    "sphinx.ext.intersphinx",
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store']

intersphinx_mapping = runpy.run_path("../intersphinx.py")["mapping"]


# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

html_theme = 'sphinx_rtd_theme'
html_static_path = ['_static']

html_css_files = ["graphvizoverwrite.css"]

# -- Graphviz -------------------------------------------------
graphviz_output_format = 'svg'
