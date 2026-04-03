FROM sharelatex/sharelatex:latest

USER root

COPY init-admin.sh /etc/my_init.d/99_create_admin.sh

RUN chmod +x /etc/my_init.d/99_create_admin.sh

RUN tlmgr option repository https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2025/tlnet-final

RUN tlmgr update --self

RUN tlmgr install scheme-full || true