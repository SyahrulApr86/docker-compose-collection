FROM sharelatex/sharelatex:latest

USER root

# script init admin
COPY init-admin.sh /etc/my_init.d/99_create_admin.sh
RUN chmod +x /etc/my_init.d/99_create_admin.sh

# gunakan repository texlive yang sesuai dengan versi Overleaf
RUN tlmgr option repository https://ftp.math.utah.edu/pub/tex/historic/systems/texlive/2025/tlnet-final

# update tlmgr
RUN tlmgr update --self

# install semua paket latex
RUN tlmgr install scheme-full