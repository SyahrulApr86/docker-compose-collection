FROM sharelatex/sharelatex:latest

USER root

RUN tlmgr option repository https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2025/tlnet-final

# update tlmgr
RUN tlmgr update --self

# install paket latex yang umum dipakai
RUN tlmgr install \
    scheme-medium \
    collection-latex \
    collection-latexextra \
    collection-fontsrecommended \
    collection-science \
    collection-bibtexextra \
    collection-pictures

USER www-data
