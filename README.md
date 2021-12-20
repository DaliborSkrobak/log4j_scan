# Log4j_scan

bash script which can scan directory for `log4j-core` packages/classes and check if are those packages upgraded.

## Usage
```shell
./log4j_scan.sh /opt
c0958cdb712dbb4fbd2fdbde6750f092 | fixed:NOT | /opt/apm-java/elastic-apm-agent.jar
90fef52890915718365075022d2a50a5 | fixed:NOT | /opt/perform/tools-6.2.4/lib/log4j-core-2.7.jar
c41c4e77e28a414e9512e889fe72c26e | fixed:NOT_FULLY | /opt/perform/tools-6.2.5/lib/log4j-core-2.16.0.jar
90fef52890915718365075022d2a50a5 | fixed:NOT | /opt/jmxeval/jmxeval/lib/log4j-core-2.7.jar
```

## How it works
I was trying to find best way to distinguish log4j versions without relaying on original JAR name or make version detection work even for repackaged class files.

I decided to use md5sum of file which is changed often to use it as version indicator.

### class file version "indicator" for all JAR versions
First I downloaded all `log4j-core` packages into directory:

```
wget -np -e robots=off -r --debug -U "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:95.0) Gecko/20100101 Firefox/95.0"  -P /var/tmp/smaz/ -A ".jar" -R "*source*" -R "*test*" -R "*javadoc*" -R "*\.\.*" https://repo1.maven.org/maven2/org/apache/logging/log4j/log4j-core/
```

I used commands below to find common class file between older and newest versions:

```shell
unzip -l log4j-core-2.0-alpha1.jar | awk '{ print $4}' | grep "class$" | sort >  /tmp/log4j-core-2.0-alpha1.lst
unzip -l log4j-core-2.17.0.jar | awk '{ print $4}' | grep "class$" | sort >  /tmp/log4j-core-2.17.0.jar.lst

comm -12 /tmp/log4j-core-2.0-alpha1.lst /tmp/log4j-core-2.17.0.jar.lst | tee /tmp/common_files.lst

for i in `cat /tmp/common_files.lst`; do
  for f in `ls *.jar`; do
    rm -rf /tmp/tmp_log4j/;
    echo -n "$i $f ";
    unzip -jqo $f $i -d /tmp/tmp_log4j;
    find /tmp/tmp_log4j/ -type f | xargs  md5sum;
  done;
done | tee /tmp/out
```

Then it is matter of preference which class file is selected as "indicator" of `log4j-core` version:

```
sort -V /tmp/out | grep -v '\$' | less
```

### generate checksums

```
for f in `ls *.jar`; do
  echo -n "$f | "; rm -rf /tmp/tmp_log4j/;
  unzip -jqo $f org/apache/logging/log4j/core/appender/AbstractManager.class -d /tmp/tmp_log4j/;
  find /tmp/tmp_log4j/ -type f | xargs  md5sum | cut -d' ' -f1 | tr -d '\n';
  echo " fixed:";
done | sort -V
```

### CHECKSUM\_NOT\_FOUND
There is possibility that checksum will not be present in the script - mainly for elastic's apm package (it looks that they recompile log4j classes).

Decompiler is only way how to find out if that version is fixed or not. I recommend `cfr decompiler`. Then clone [log4j  github repository](https://github.com/apache/logging-log4j2.git) and find if JAR contains fixes or not.