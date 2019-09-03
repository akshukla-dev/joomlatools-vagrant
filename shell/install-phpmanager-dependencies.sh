#!/bin/bash
# Installs and builds the dependencies used by
# phpmanager to be able to compile different
# PHP versions.

## Configuration
DESTINATION_DIR=/usr/local/src
WORK_DIR=/tmp/phpmanager-dependencies
INSTALL_DIR=/opt
LOGFILE=/tmp/install-phpmanager-dependencies.log

## Functions

# sub_execute()
#
# Execute a command in the background and
# wait for it to end, while logging output
# to logfile.
sub_execute() {
    CMD="$1"
    NAME="$2"
    LOGFILE="$3"
    MSG="$4"

    $CMD >> "$LOGFILE" 2>&1 &
    PID=$!

    sub_waitinganim $PID "$MSG"

    wait $PID

    if [[ $? -ne 0 ]] ; then
        tail -n 5 "${LOGFILE}"
        echo -e "\033[31mERROR: ${NAME} failed!\e[0m"
        echo "See ${LOGFILE} for more details."
        exit 1
    fi
}

# sub_waitinganim()
#
# Display a "loading animation" while given process is running
# From: http://stackoverflow.com/questions/12498304/using-bash-to-display-a-progress-working-indicator
sub_waitinganim() {
    PID=$1
    TEXT=$2

    SPIN='-\|/'
    i=0
    while kill -0 $PID &> /dev/null
    do
      i=$(( (i+1) % 4 ))
      printf "\r${TEXT} .. \e[1;32m${SPIN:$i:1} \e[0m \033[?25l"
      sleep .1
    done

    echo -e "\r${TEXT} .. \e[92mfinished\e[0m \033[?25h"
}

# sub_download()
#
# Download and extract the tarball from URL
sub_download() {
    URL="$1"
    FILE=$(basename $URL)

    CMD="wget -nv ${URL} -O ${WORK_DIR}/${FILE}"
    sub_execute "$CMD" "wget ${FILE}" "${LOGFILE}" "Downloading ${FILE}"

    cd "${DESTINATION_DIR}"

    CMD="tar -zxf ${WORK_DIR}/${FILE}"
    sub_execute "$CMD" "extract ${FILE}" "${LOGFILE}" "Extracting archive ${FILE}"

    rm -f "${WORK_DIR}/${FILE}"
}

# sub_build()
#
# Build and install the package
sub_build() {
    PACKAGE="$1"
    CONFIGURE_OPTS="$2"

    cd "${DESTINATION_DIR}/${PACKAGE}"

    if [[ $PACKAGE == "icu-60_2" ]]; then
        cd "${DESTINATION_DIR}/${PACKAGE}/source"
    fi

    CONFIG_SCRIPT="./configure"
    if [[ $PACKAGE == openssl-* ]]; then
        CONFIG_SCRIPT="./config"
    fi

    CMD="./${CONFIG_SCRIPT} --prefix=${INSTALL_DIR}/${PACKAGE} ${CONFIGURE_OPTS}"
    sub_execute "$CMD" "./${CONFIG_SCRIPT} ${PACKAGE}" "${LOGFILE}" "Configuring ${PACKAGE}"

    CMD="make --silent"
    sub_execute "$CMD" "make ${PACKAGE}" "${LOGFILE}" "Build ${PACKAGE}"

    if [[ $PACKAGE == openssl-* ]]; then
        CMD="make --silent depend"
        sub_execute "$CMD" "generate ${PACKAGE} dependencies" "${LOGFILE}" "Generate ${PACKAGE} dependencies"

        CMD="sudo make --silent install_sw"
        sub_execute "$CMD" "install ${PACKAGE}" "${LOGFILE}" "Install ${PACKAGE}"
    else
        CMD="sudo make --silent install"
        sub_execute "$CMD" "install ${PACKAGE}" "${LOGFILE}" "Install ${PACKAGE}"
    fi
}

## Start of script

echo "" > $LOGFILE
mkdir -p $DESTINATION_DIR $WORK_DIR

# Install all packages that are available via the repositories
CMD="sudo apt-get -q -y install autoconf2.13 re2c bison libcurl4-openssl-dev libmariadb-dev libmariadb-dev-compat libmcrypt-dev libbz2-dev libjpeg-dev libpng-dev libfreetype6-dev libicu-dev libxml2-dev libxslt1-dev libssl-dev libreadline-dev libzip-dev libreadline-dev"
sub_execute "$CMD" "apt-get" "${LOGFILE}" "Install dependencies from Ubuntu repositories"

# Download external packages
URLS=(
  'http://ftp.gnu.org/gnu/bison/bison-2.2.tar.gz'
  'http://ftp.gnu.org/gnu/bison/bison-2.4.tar.gz'
  'https://ftp.gnu.org/old-gnu/gnu-0.2/src/flex-2.5.4.tar.gz'
  'https://www.openssl.org/source/openssl-1.0.2g.tar.gz'
  'ftp://xmlsoft.org/libxml2/libxml2-2.7.8.tar.gz'
  'ftp://xmlsoft.org/libxslt/libxslt-1.1.26.tar.gz'
  'http://download.icu-project.org/files/icu4c/60.2/icu4c-60_2-src.tgz'
)

for URL in "${URLS[@]}"
do
    sub_download $URL
done

mv "${DESTINATION_DIR}/icu" "${DESTINATION_DIR}/icu-60_2"

# Build the downloaded dependencies
sub_build "bison-2.2"
sub_build "bison-2.4"
sub_build "libxml2-2.7.8"
sub_build "libxslt-1.1.26" "--with-libxml-prefix=/opt/libxml2-2.7.8/ --with-libxml-libs-prefix=/opt/libxml2-2.7.8/ --with-libxml-include-prefix=/opt/libxml2-2.7.8/"
sub_build "icu-60_2"

sub_build "openssl-1.0.2g" "-fPIC no-gost"

PATH="${PATH}:${INSTALL_DIR}/bison-2.2/bin"
sub_build "flex-2.5.4"

# Set-up symlinks
sudo ln -fs /opt/openssl-1.0.2g/lib /opt/openssl-1.0.2g/lib/x86_64-linux-gnu
sudo ln -fs /usr/include/x86_64-linux-gnu/curl /usr/include/curl

# Install a default CA bundle into OpenSSL to verify the peer certificates
sudo wget -q http://curl.haxx.se/ca/cacert.pem -O /opt/openssl-1.0.2g/ssl/cert.pem
