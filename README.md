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
make dev
open http://127.0.0.1:8000/
```

## Publish

```sh
make pub
open https://tonygilkerson.github.io/ckad/
```

## Notes

### Todos

Start this free course:

- [ ] - https://learning.edx.org/course/course-v1:LinuxFoundationX+LFS158x+1T2024/home

Read up on next steps for taking the exam. Document some of the experience:

- [ ] - https://trainingportal.linuxfoundation.org/courses/certified-kubernetes-application-developer-ckad