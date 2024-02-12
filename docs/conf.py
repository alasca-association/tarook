# Configuration file for the Sphinx documentation builder.
#
# For the full list of built-in configuration values, see the documentation:
# https://www.sphinx-doc.org/en/master/usage/configuration.html

# -- Project information -----------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#project-information

project = 'Yaook k8s'
copyright = '2020-2024, Yaook Authors'
author = 'Yaook Authors'

# -- General configuration ---------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#general-configuration

extensions = [
    'sphinx_rtd_theme',
    'sphinx.ext.autodoc',
    'sphinx.ext.autosummary',
    'sphinx.ext.todo',
    'sphinx_multiversion',
    'sphinx_tabs.tabs'
]

templates_path = ['_templates']
exclude_patterns = ['_build', 'Thumbs.db', '.DS_Store', '_releasenotes/*', 'README.md']

# -- Options for HTML output -------------------------------------------------
# https://www.sphinx-doc.org/en/master/usage/configuration.html#options-for-html-output

# html_theme = 'sphinx_rtd_theme'
html_theme = 'furo'
html_static_path = ['_static']

# -- Furo --------------------------------------------------------------------
html_theme_options = {
    "sidebar_hide_name": True,
}
html_logo = "img/yaook-husky-small.png"
html_favicon = 'img/yaook-husky-small.png'
html_css_files = [
    'dropup.css',
]

# -- Todo --------------------------------------------------------------------
# display todos
todo_include_todos = True

# -- Autosection -------------------------------------------------------------
# autosectionlabel_prefix_document = True

# -- Multiversion ------------------------------------------------------------
smv_branch_whitelist = r'(devel|release\/v\d+\.\d+)$'
# None leads to warnings, so we use an impossible match
smv_tag_whitelist = r'matchnothing^'
smv_remote_whitelist = r'^origin$'
smv_released_pattern = r'^.*release\/v\d+\.\d+.*$'

# get latest version
f = open("../version", "r")
lines = f.readlines()
min_version = lines[0].rpartition('.')[0]
smv_latest_version = f"release/v{min_version}"
print(smv_latest_version)
