
## Notes

July 11th
Plan is to make progress on data engineering all my coaching calls into pose sequences


## Timeline estimates

 - Design a webpage -> 1 week
 - Fill webpage with words -> 1 week
 - Setup the data pipeline -> 2 weeks
 - Create an analysis -> 1 week
 - Create a ui to browse videos -> 2 weeks

## Use similar libraries as Graphistry:

```
core_requires = [
  'numpy',
  'pandas >= 0.17.0',
  'pyarrow >= 0.15.0',
  'requests',
  'typing-extensions',
  'packaging >= 20.1'
]

stubs = [
  'pandas-stubs', 'types-requests'
]

dev_extras = {
    'docs': ['sphinx==3.4.3', 'docutils==0.16', 'sphinx_autodoc_typehints==1.11.1', 'sphinx-rtd-theme==0.5.1', 'Jinja2<3.1'],
    'test': ['flake8', 'mock', 'mypy', 'pytest'] + stubs,
    'build': ['build']
}

base_extras = {
    'igraph': ['python-igraph'],
    'networkx': ['networkx>=2.5'],
    'gremlin': ['gremlinpython'],
    'bolt': ['neo4j', 'neotime'],
    'nodexl': ['openpyxl', 'xlrd'],
    'jupyter': ['ipython'],
    'umap-learn': ['umap-learn', 'dirty-cat==0.2.0', 'scikit-learn>=1.0'],
    'ai': ['scikit-learn>=1.0', 'scipy', 'dirty-cat==0.2.0', 'umap-learn', 'dgl', 'torch',
           'sentence-transformers']
}
```