LATEXDIR=latex/
GCC=g++
SAMTOOLS_DIR=samtools-0.1.18/

.PHONY: all clean test

all:  sjcount 

clean ::
	rm -f -r sjcount progressbar.o

${SAMTOOLS_DIR}libbam.a:
	wget --no-check-certificate http://sourceforge.net/projects/samtools/files/samtools/0.1.18/samtools-0.1.18.tar.bz2
	tar -xf samtools-0.1.18.tar.bz2
	rm -f samtools-0.1.18.tar.bz2
	make -C samtools-0.1.18 all
	# If SAMTOOLS is already installed, you might want to update SAMTOOLS_DIR path without installing a fresh copy

progressbar.o : progressbar.c progressbar.h
	$(GCC) -c progressbar.c 

sjcount : sjcount.c progressbar.o ${SAMTOOLS_DIR}libbam.a
	$(GCC) -I ${SAMTOOLS_DIR} sjcount.c progressbar.o ${SAMTOOLS_DIR}libbam.a -lz -o sjcount

######################################################################################################################

TESTDIR=test/
TESTBAM=${TESTDIR}test.bam

PARAMS=-nbins 50 -read1 0 -read2 0 -quiet -lim 1000000

${TESTDIR}test.bam : 
	wget http://cb.skoltech.ru/dp/ipsa/ENCFF054FHQ.bam  -O ${TESTDIR}test.bam

${TESTDIR}test.ssj ${TESTDIR}test.ssc : ${TESTBAM} sjcount
	./sjcount -bam ${TESTBAM} ${PARAMS} -ssj ${TESTDIR}test.ssj -ssc ${TESTDIR}test.ssc

${TESTDIR}control.ssj : ${TESTBAM} ${TESTDIR}sam2sj3.pl
	${SAMTOOLS_DIR}samtools view ${TESTBAM}  | perl ${TESTDIR}sam2sj3.pl ${PARAMS} | sort > ${TESTDIR}control.ssj

${TESTDIR}control.ssc : ${TESTBAM} ${TESTDIR}sam2sb3.pl  ${TESTDIR}test.ssj
	${SAMTOOLS_DIR}samtools view ${TESTBAM}  |  perl ${TESTDIR}sam2sb3.pl -ssj ${TESTDIR}test.ssj ${PARAMS} | sort > ${TESTDIR}control.ssc



test :: ${TESTDIR}test.ssj ${TESTDIR}control.ssj ${TESTDIR}test.ssc ${TESTDIR}control.ssc
	sort ${TESTDIR}test.ssj | cmp ${TESTDIR}control.ssj
	sort ${TESTDIR}test.ssc | cmp ${TESTDIR}control.ssc
	#===> tests v3 passed successfully <===#

clean ::
	rm -f ${TESTDIR}test.ssj ${TESTDIR}control.ssj
