#!/bin/bash
set -o pipefail

# Usage:
#   log4j_scan.sh <directory>

SCRIPT=`basename $0`
pushd `dirname $0` > /dev/null
SCRIPT_DIR=`pwd -P`
popd > /dev/null

SCAN_DIR=${1:?Please provide directory to scan}

# entire file is not specified below, because apm_agent's classes are renamed to  `*.esclass`  
CHECKSUM_CLASS='org/apache/logging/log4j/core/config/AppenderControl\.'

# Checksum definition, created by:
# # unzip -oj log4j-core-2.17.0.jar org/apache/logging/log4j/core/LoggerContext.class -d /tmp/
# # md5sum /tmp/LoggerContext.class

CHECKSUMS="elastic-apm-agent.jar | c0958cdb712dbb4fbd2fdbde6750f092 fixed:NOT
log4j-core-2.0-alpha1.jar | e643e66b2514049e3051fcd5855a5cdc fixed:NOT
log4j-core-2.0-alpha2.jar | e643e66b2514049e3051fcd5855a5cdc fixed:NOT
log4j-core-2.0-beta1.jar | e643e66b2514049e3051fcd5855a5cdc fixed:NOT
log4j-core-2.0-beta2.jar | e643e66b2514049e3051fcd5855a5cdc fixed:NOT
log4j-core-2.0-beta3.jar | 6ddf69a467526239aac58c3136ba2649 fixed:NOT
log4j-core-2.0-beta4.jar | 90c7973b0be0a26dcf3fa70defd08685 fixed:NOT
log4j-core-2.0-beta5.jar | bdfae43813139e23ecc965fe6eeb6213 fixed:NOT
log4j-core-2.0-beta6.jar | bdfae43813139e23ecc965fe6eeb6213 fixed:NOT
log4j-core-2.0-beta7.jar | bdfae43813139e23ecc965fe6eeb6213 fixed:NOT
log4j-core-2.0-beta8.jar | bdfae43813139e23ecc965fe6eeb6213 fixed:NOT
log4j-core-2.0-beta9.jar | ef4fa89f686d1c2d685b72cc14b3f573 fixed:NOT
log4j-core-2.0-rc1.jar | 18ebbc23bab68f3037516aefa7cd2855 fixed:NOT
log4j-core-2.0-rc2.jar | 5c2a4e086a84173ee9183c7f233cd83b fixed:NOT
log4j-core-2.0.1.jar | 5c2a4e086a84173ee9183c7f233cd83b fixed:NOT
log4j-core-2.0.2.jar | 5c2a4e086a84173ee9183c7f233cd83b fixed:NOT
log4j-core-2.0.jar | 5c2a4e086a84173ee9183c7f233cd83b fixed:NOT
log4j-core-2.1.jar | ef186852471ad4dbec1a7ad2c0e28eac fixed:NOT
log4j-core-2.2.jar | ef186852471ad4dbec1a7ad2c0e28eac fixed:NOT
log4j-core-2.3.jar | ef186852471ad4dbec1a7ad2c0e28eac fixed:NOT
log4j-core-2.4.1.jar | 69ab1110ca1e38c490b26b2e522344ea fixed:NOT
log4j-core-2.4.jar | c6cd3cf88345b387bb4fedbb20cf5258 fixed:NOT
log4j-core-2.5.jar | 0f6b318aace8ef0dff915b8993cbc702 fixed:NOT
log4j-core-2.6.1.jar | d22dec97e9446acb9105b315ee7255ee fixed:NOT
log4j-core-2.6.2.jar | d22dec97e9446acb9105b315ee7255ee fixed:NOT
log4j-core-2.6.jar | d22dec97e9446acb9105b315ee7255ee fixed:NOT
log4j-core-2.7.jar | 90fef52890915718365075022d2a50a5 fixed:NOT
log4j-core-2.8.1.jar | 90fef52890915718365075022d2a50a5 fixed:NOT
log4j-core-2.8.2.jar | 44e2fae82d16e9e6ebfb3678f4f8c672 fixed:NOT
log4j-core-2.8.jar | 90fef52890915718365075022d2a50a5 fixed:NOT
log4j-core-2.9.0.jar | 90fef52890915718365075022d2a50a5 fixed:NOT
log4j-core-2.9.1.jar | 90fef52890915718365075022d2a50a5 fixed:NOT
log4j-core-2.10.0.jar | 90fef52890915718365075022d2a50a5 fixed:NOT
log4j-core-2.11.0.jar | 90fef52890915718365075022d2a50a5 fixed:NOT
log4j-core-2.11.1.jar | 90fef52890915718365075022d2a50a5 fixed:NOT
log4j-core-2.11.2.jar | f7bf7f7725f15ec5c19932ff46b2d847 fixed:NOT
log4j-core-2.12.0.jar | 732433d9388411b5f714f5d89fc41a48 fixed:NOT
log4j-core-2.12.1.jar | 732433d9388411b5f714f5d89fc41a48 fixed:NOT
log4j-core-2.12.2.jar | 732433d9388411b5f714f5d89fc41a48 fixed:NOT
log4j-core-2.13.0.jar | eeab113e5386ceb0b1906af06ed43e04 fixed:NOT
log4j-core-2.13.1.jar | eeab113e5386ceb0b1906af06ed43e04 fixed:NOT
log4j-core-2.13.2.jar | eeab113e5386ceb0b1906af06ed43e04 fixed:NOT
log4j-core-2.13.3.jar | eeab113e5386ceb0b1906af06ed43e04 fixed:NOT
log4j-core-2.14.0.jar | 997da7b3fd408f542f54dfb204c5fde6 fixed:NOT
log4j-core-2.14.1.jar | 452cadcd8f4da1e56755cdc106989e6a fixed:NOT
log4j-core-2.15.0.jar | 445b65145d2e9ccbdcd0238e20acc15a fixed:NOT_FULLY
log4j-core-2.16.0.jar | c41c4e77e28a414e9512e889fe72c26e fixed:NOT_FULLY
log4j-core-2.17.0.jar | e7cd10930f7efcf09c43fd580f476491 fixed:yes"

ALL_JARS=$(find ${SCAN_DIR} -name "*.jar" 2>/dev/null; find ${SCAN_DIR} -name "*.war" 2>/dev/null)

# =================
# JAR/WAR scanning
# =================

for f in $ALL_JARS; do
  class=$(unzip -l $f 2>/dev/null| grep "${CHECKSUM_CLASS}" | awk '{print $4}')
  test -z "$class" && continue
  
  test 1=$(echo "$class" | wc -l) || { echo "file: $f - Unexpected number of classes: $class"; exit 1; }
  rm -rf /tmp/log4j_check_sum/
  unzip -qoj $f $class -d /tmp/log4j_check_sum/ 
  file_sum=$(find /tmp/log4j_check_sum/ -type f | xargs md5sum | awk '{print $1}')

  echo -n "${file_sum} | "
  echo "${CHECKSUMS}" | grep $file_sum | grep -o "fixed:.*" | head -1 |  tr -d '\n' && echo " | $f" || echo "CHECKSUM_NOT_FOUND | $f"

done 

# =====================
# *.class file scanning
# =====================

for f in `find . -name "*.class" 2>/dev/null| grep "${CHECKSUM_CLASS}"`; do
  file_sum=$(md5sum $f | awk '{print $1}')
  echo "${CHECKSUMS}" | grep $file_sum | grep -o "NOT.*" |  tr -d '\n' && echo " - $f"
done


