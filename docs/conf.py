# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'yaook/k8s'
copyright = '2020-2024, Yaook Authors'
author = 'YAOOK Authors'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx_rtd_theme',
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.todo',
    'sphinx_multiversion',
    'sphinx_tabs.tabs',
    "sphinx_design",
    'myst_parser',
    'sphinx_copybutton'
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store',
                    '_releasenotes/*', 'README.md',
                    ".terraform-doc-header.md"]

myst_enable_extensions = ["colon_fence"]

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output
# html_theme = 'sphinx_rtd_theme'
html_theme = 'furo'
html_static_path = ['_static']

# -- Furo --------------------------------------------------------------------
html_theme_options = {
    "sidebar_hide_name": True,
    "source_repository": "https://gitlab.com/yaook/k8s",
    "source_branch": "devel",
    "source_directory": "docs/",
}
html_logo = "_static/yaook-husky-small.png"
html_favicon = '_static/Husky_blue.svg'
html_css_files = [
    'dropup.css',
]

# -- copybutton --------------------------------------------------------------
# don't copy console prompts
copybutton_exclude = '.linenos, .gp'

# -- Todo --------------------------------------------------------------------
# display todos
todo_include_todos = True

# -- Autosection -------------------------------------------------------------
# autosectionlabel_prefix_document = True

# -- Multiversion ------------------------------------------------------------
smv_branch_whitelist = r'(devel|release\/v\d+\.\d+)$'
# None leads to warnings, so we use an impossible match instead
smv_tag_whitelist = r'matchnothing^'
smv_remote_whitelist = r'^origin$'
smv_released_pattern = r'^.*release\/v\d+\.\d+.*$'

# get latest version
f = open("../version", "r")
lines = f.readlines()
min_version = lines[0].rpartition('.')[0]
smv_latest_version = f"release/v{min_version}"
print(smv_latest_version)
