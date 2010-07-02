# Makefile for GNU Awk.
#
# Rewritten by Arnold Robbins, September 1988, March 1989.
#
# Copyright (C) 1986, 1988, 1989 the Free Software Foundation, Inc.
# 
# This file is part of GAWK, the GNU implementation of the
# AWK Progamming Language.
# 
# GAWK is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 1, or (at your option)
# any later version.
# 
# GAWK is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with GAWK; see the file COPYING.  If not, write to
# the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

# CFLAGS: options to the C compiler
#
#	-O	optimize
#	-g	include dbx/sdb info
#	-gg	include gdb debugging info; only for GCC
#	-pg	include new (gmon) profiling info
#	-p	include old style profiling info (System V)
#
#	-DNOVPRINTF - system has no vprintf and associated routines
#	-DHASDOPRNT - system needs version of vprintf et al. defined in awk5.c
#		      and has a BSD compatable doprnt()
#	-DNOMEMCMP  - system lacks memcmp()
#	-DUSG       - system is generic-ish System V.
#
OPTIMIZE=-O
DEBUG=#-DDEBUG #-DFUNC_TRACE -DMEMDEBUG
DEBUGGER=#-g
PROFILE=#-pg
SYSV=
BSD=#-DHASDOPRNT
MEMCMP=#-DNOMEMCMP
VPRINTF=#-DNOVPRINTF
  
FLAGS= $(OPTIMIZE) $(SYSV) $(DEBUG) $(BSD) $(MEMCMP) $(VPRINTF)
CFLAGS= $(FLAGS) $(DEBUGGER) $(PROFILE) 
LDFLAGS= #-Bstatic

SRC =	awk1.c awk2.c awk3.c awk4.c awk5.c \
	awk6.c awk7.c awk8.c awk9.c version.c do_free.c awka.c

PCSTUFF= makefile.pc names.lnk random.c

AWKOBJS = awk1.o awk2.o awk3.o awk4.o awk5.o awk6.o awk7.o awk8.o awk9.o \
		version.o awka.o # do_free.o # used for MEMDEBUG
ALLOBJS = $(AWKOBJS) awk.tab.o

# Parser to use on grammar -- if you don't have bison use the first one
#PARSER = yacc
PARSER = bison

# S5OBJS
#	Set equal to alloca.o if your system is S5 and you don't have
#	alloca. Uncomment the rule below to actually make alloca.o.
S5OBJS=

# GETOPT
#	Set equal to getopt.o if you have a generic BSD system. The
#	generic BSD getopt is reported to not work with gawk. The
#	gnu getopt is supplied in gnu.getopt.c. The Public Domain
#	getopt from AT&T is in att.getopt.c. Choose one of these,
#	and rename it getopt.c.
GETOPT=

# LIBOBJS
#	Stuff that awk uses as library routines, but not in /lib/libc.a.
LIBOBJS= regex.o $(S5OBJS) $(GETOPT)

UPDATES = Makefile awk.h awk.y \
	$(SRC) regex.c regex.h

INFOFILES= gawk-info gawk-info-1 gawk-info-2 gawk-info-3 gawk-info-4 \
           gawk-info-5 gawk.aux gawk.cp gawk.cps gawk.dvi gawk.fn gawk.fns \
           gawk.ky gawk.kys gawk.pg gawk.pgs gawk.texinfo gawk.toc \
           gawk.tp gawk.tps gawk.vr gawk.vrs

# DOCS
#	Documentation for users
#
DOCS=gawk.1 $(INFOFILES)

# We don't distribute shar files, but they're useful for mailing.
SHARS = $(DOCS) COPYING README PROBLEMS $(UPDATES) awk.tab.c \
	alloca.s alloca.c att.getopt.c gnu.getopt.c $(PCSTUFF)

gawk: $(ALLOBJS) $(LIBOBJS)
	$(CC) -o gawk $(CFLAGS) $(ALLOBJS) $(LIBOBJS) -lm $(LDFLAGS)

$(AWKOBJS): awk.h

awk.tab.o: awk.h awk.tab.c

awk.tab.c: awk.y
	$(PARSER) -v awk.y
	-mv -f y.tab.c awk.tab.c

# Alloca: uncomment this if your system (notably System V boxen)
# does not have alloca in /lib/libc.a
#
#alloca.o: alloca.s
#	/lib/cpp < alloca.s | sed '/^#/d' > t.s
#	as t.s -o alloca.o
#	rm t.s

# If your machine is not supported by the assembly version of alloca.s,
# use the C version instead.  This uses the default rules to make alloca.o.
#
#alloca.o: alloca.c

lint: $(SRC)
	lint -hcbax $(FLAGS) $(SRC) awk.tab.c

clean:
	rm -f gawk *.o core awk.output awk.tab.c gmon.out make.out

awk.shar: $(SHARS)
	shar -f awk -c $(SHARS)
 
awk.tar: $(SHARS)
	tar cvf awk.tar $(SHARS)

updates.tar:	$(UPDATES)
	tar cvf gawk.tar $(UPDATES)
 
awk.tar.Z:	awk.tar
	compress < awk.tar > awk.tar.Z

doc: $(DOCS)
	nroff -man $(DOCS) | col > $(DOCS).out

# This command probably won't be useful to the rest of the world, but makes
# life much easier for me.
dist:	awk.tar awk.tar.Z

diff:
	for i in RCS/*; do rcsdiff -c -b $$i > `basename $$i ,v`.diff; done

update:	$(UPDATES)
	sendup $?
	touch update

release: $(SHARS)
	-rm -fr gawk-dist
	mkdir gawk-dist
	cp -p $(SHARS) gawk-dist
	tar -cvf - gawk-dist | compress > dist.tar.Z
