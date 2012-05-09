# Defining variables ===============================
FC = gfortran
MODFLAG = -J
FCFLAGS = $(MODFLAG)$(MODDIR)

CC = g++
CCINCLUDE = /home/kmtu/local/voro++-0.4.4/include/voro++/
CCLIBDIR = /home/kmtu/local/voro++-0.4.4/lib/ 
CCLIB = voro++

SRCDIR = ./
#OBJDIR = ./obj/
MODDIR = ../mod/
#LIBDIR = $(SRCDIR)lib/
OUTDIR = ../out/

#PROGRAM = $(OUTDIR)voronoi-f $(OUTDIR)voronoi-c

vpath %.f90 $(SRCDIR)
vpath %.o $(SRCDIR)
#vpath % $(OUTDIR)

# Program ==================================
all : f90 cpp
.PHONY : all 

# ---------------------------
f90 : voronoi-f
.PHONY : f90

voronoi-f : voronoi-f.o
	$(FC) -o $(OUTDIR)$(@F) $^

voronoi-f.o : voronoi-f.f90
	$(FC) -o $(SRCDIR)$(@F) -c $< $(FCFLAGS)

# ---------------------------
cpp : voronoi-c
.PHONY : cpp

voronoi-c : voronoi-c.o
	$(CC) -o $(OUTDIR)$(@F) $^ -L$(CCLIBDIR) -l$(CCLIB) 

voronoi-c.o : voronoi-c.cpp
	$(CC) -o $(SRCDIR)$(@F) -c $< -I$(CCINCLUDE)

# Library ===================================
#nrtype.o : nrtype.f90
#	$(FC) -o $(LIBDIR)$(@F) -c $< $(FCFLAGS)
#==================================================
.PHONY: clean
clean :
	rm -f $(SRCDIR)*.o $(MODDIR)*.mod
	rm -f $(PROGRAM)
	rm -f *~ $(SRCDIR)*~
