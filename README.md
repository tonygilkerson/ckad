# ckad

Information and practice for CKAD.

This repo uses [mkdocs](https://www.mkdocs.org/) ([help](https://mkdocs.readthedocs.io/en/0.10/)) and [github pages](https://help.github.com/articles/configuring-a-publishing-source-for-github-pages/) to host content at:

https://tonygilkerson.github.io/ckad/

## One-time setup

```sh
python3 -m venv .venv
source .venv/bin/activate
pip3 install mkdocs-material
```

## Develop

```sh
# Active python environment
source .venv/bin/activate

# Serve the doc
mkdocs serve
# Edit content and review changes here:
open http://127.0.0.1:8000/
```

## Publish

```sh
make publish
open https://tonygilkerson.github.io/ckad/
```
