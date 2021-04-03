#This is free and unencumbered software released into the public domain.
#
#Anyone is free to copy, modify, publish, use, compile, sell, or
#distribute this software, either in source code form or as a compiled
#binary, for any purpose, commercial or non-commercial, and by any means.
#
#In jurisdictions that recognize copyright laws, the author or authors
#of this software dedicate any and all copyright interest in the
#software to the public domain. We make this dedication for the benefit
#of the public at large and to the detriment of our heirs and
#successors. We intend this dedication to be an overt act of
#relinquishment in perpetuity of all present and future rights to this
#software under copyright law.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
#EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
#MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
#IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
#OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
#ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
#OTHER DEALINGS IN THE SOFTWARE.
#
#For more information, please refer to <http://unlicense.org/>

CNAME=im_really_bored
CFLAGS=-O0 -s -nostdlib -nodefaultlibs
CPKGS=gcc
PWD=$(shell pwd)
PNAME=program
DFILE=${PWD}/Dockerfile
EFILE=${PWD}/Dockerentry.sh
CFILE=${PWD}/${PNAME}.c
DDIR=/root

all: clean schecks ${PNAME}.c Dockerentry.sh Dockerfile build_img run clean
.PHONY: clean schecks build_img run

clean:
	rm -rv ${DFILE} ${EFILE} ${CFILE} 2>&1 >/dev/null || test 1
	docker rmi -f ${CNAME}:latest 2>&1 >/dev/null || test 1

schecks:
	which docker >/dev/null
	ping -c3 debian.org >/dev/null

${PNAME}.c:
	echo "#define REALINLINE __attribute__((always_inline)) inline" >> ${CFILE}
	echo "REALINLINE void leave_not_ok(void) {" >> ${CFILE}
	echo "	register int rax asm(\"rax\") = 60;" >> ${CFILE}
	echo "	register int rdi asm(\"rdi\") = 0;" >> ${CFILE}
	echo "	asm(\"syscall\");" >> ${CFILE}
	echo "}" >> ${CFILE}
	echo "REALINLINE void say_last_words(void) {" >> ${CFILE}
	echo "	register int rax asm(\"rax\") = 1;" >> ${CFILE}
	echo "	register int rdi asm(\"rdi\") = 1;" >> ${CFILE}
	echo "	register const char *rsi asm(\"rsi\") = \"Goodbye world\\n\";" >> ${CFILE}
	echo "	register int rdx asm(\"rdx\") = 14;" >> ${CFILE}
	echo "	asm(\"syscall\");" >> ${CFILE}
	echo "}" >> ${CFILE}
	echo "void _start() {" >> ${CFILE}
	echo "	say_last_words();" >> ${CFILE}
	echo "	leave_not_ok();" >> ${CFILE}
	echo "}" >> ${CFILE}

Dockerentry.sh:
	echo "#!/bin/sh" >> ${EFILE} 
	echo "ldd ${DDIR}/program.bin" >> ${EFILE}
	echo "${DDIR}/program.bin" >> ${EFILE}

Dockerfile:
	echo "FROM debian:stable-slim" >> ${DFILE}
	echo "ENV DEBIAN_FRONTEND=noninteractive" >> ${DFILE}
	echo "WORKDIR ${DDIR}" >> ${DFILE}
	echo "ADD ${PNAME}.c ${DDIR}/${PNAME}.c" >> ${DFILE}
	echo "ADD Dockerentry.sh ${DDIR}/Dockerentry.sh" >> ${DFILE}
	echo "RUN chmod +x ${DDIR}/Dockerentry.sh" >> ${DFILE}
	echo "RUN apt-get update && apt-get -y upgrade && \\" >> ${DFILE}
	echo "apt-get install --no-install-recommends --yes ${CPKGS} &&\\" >> ${DFILE}
	echo "apt-get clean" >> ${DFILE}
	echo "RUN gcc ${CFLAGS} -o ${DDIR}/${PNAME}.bin ${DDIR}/${PNAME}.c" >> ${DFILE}
	echo "ENTRYPOINT [\"${DDIR}/Dockerentry.sh\"]" >> ${DFILE}

build_img:
	docker build --force-rm --no-cache -t ${CNAME} . || make clean

run:
	docker run -it ${CNAME}
