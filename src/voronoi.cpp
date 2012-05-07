#include <argp.h> /* argument parse */
#include <iostream> /* cin cout cerr */
#include <fstream>
#include <vector>
#include <string>
#include <cstdlib> /* exit() */
#include <sstream> /* stringstream */
#include <cmath> /* pow() */
#include "voro++.hh"

using namespace voro;
using namespace std;

/********** argp start **********/
const char* argp_program_version = "Voronoi 0.1";
const char* argp_program_bug_address = "kmtu@nmr.kuicr.kyoto-u.ac.jp";

/* Program documentation. */
static char doc[] = "Voronoi anaylsis";

/* A description of the arguments we accept. */
static char args_doc[] = "dataFile(s)...";

/* The options we understand. */
static struct argp_option options[] = {
    {"output",   'o', "outFile", 0,  "Output file." },
    { 0 }
};

/* Used by main to communicate with parse_opt. */
struct arguments
{
    vector<string> dataFilenames;
    string outFilename;            /* file arg to ‘--output’ */
};

/* Parse a single option. */
static error_t parse_opt(int key, char* arg, struct argp_state* state)
{
    /* Get the input argument from argp_parse, which we
      know is a pointer to our arguments structure. */
    struct arguments* arguments = static_cast<struct arguments*> (state->input);

    switch(key)
    {
    case 'o':
       arguments->outFilename = arg;
       break;

    case ARGP_KEY_NO_ARGS:
       argp_usage (state);

    case ARGP_KEY_ARG:
       arguments->dataFilenames.push_back(arg);
       break;

    default:
       return ARGP_ERR_UNKNOWN;
    }
    return 0;
}

/* Our argp parser. */
static struct argp argp = { options, parse_opt, args_doc, doc };
/********** argp end **********/

int main(int argc, char** argv) {
    struct arguments arguments;
    string line;

    /* Default values for arguments*/
    arguments.outFilename = "voronoi.out";

    /* Parse our arguments; every option seen by parse_opt will be
      reflected in arguments. */
    argp_parse (&argp, argc, argv, 0, 0, &arguments);

    /* Show the parsed arguments on the screen */
    cout << "Voronoi analysis" << endl;
    cout << "outFile name = " << arguments.outFilename << endl;

    if (arguments.dataFilenames.size() > 0)
    {
        cout << "dataFile name(s) = ";
        for (vector<string>::iterator it = arguments.dataFilenames.begin();
             it != arguments.dataFilenames.end(); it++)
        {
            if (it == arguments.dataFilenames.begin())
                cout << *it;
            else
                cout << ", " << *it;
        }
        cout << endl;
    }
    else
    {
        cerr << " Error: dataFile(s) must be given ";
        exit(1);
    }
    
    /* Check outFile's availabilty */
    ofstream outFile(arguments.outFilename.c_str());
    if (!outFile.is_open())
    {
        cerr << "Error: unable to open outFile, " << arguments.outFilename << endl;
        exit(1);
    }
    
    /* Go through each dataFile */
    stringstream ssline;
    for (vector<string>::iterator it = arguments.dataFilenames.begin();
         it != arguments.dataFilenames.end(); it++)
    {
        int numFrames = 0;
        int numAtoms = 0;
        int dummy = 0;
        int lineIndex = 0;
        int numUnitCellPoints = 0;
        int numAtomsPerMolecule = 0;

        /* Create dataFile object for input*/
        ifstream dataFile(it->c_str());
        if (dataFile.is_open())
        {
            cout << "Reading " << *it << " ..." << endl;
            while (dataFile.good())
            {
                /* Read and process dataFile */
                lineIndex++;
                getline(dataFile, line);
                ssline.clear();
                ssline.str(line);

                if (lineIndex == 1)
                {
                    ssline >> numFrames >> dummy >> dummy >> numAtoms;
                    cout << "numFrames = " << numFrames << endl;
                    cout << "numAtoms = " << numAtoms << endl;
                }
                else if (lineIndex == 9)
                {
                    /* Only the first type of molecules are analyzed */
                    ssline >> numUnitCellPoints;
                    cout << "numUnitCellPoints = " << numUnitCellPoints << endl;
                }
                else if (lineIndex == 10)
                {
                    ssline >> numAtomsPerMolecule;
                    cout << "numAtomsPerMolecule = " << numAtomsPerMolecule << endl;
    
                    /* Read data frame by frame */
                    for (int iFrame = 0; iFrame < numFrames; iFrame++)
                    {
                        /* Report progress on screen */
                        int progress = int(double(iFrame)/double(numFrames)*100);
                        int nextProgress = int(double(iFrame + 1)/double(numFrames)*100);
                        if (progress < nextProgress) cout << nextProgress << "% is done" << endl;

                        double boxDimX = .0; 
                        double boxDimY = .0;
                        double boxDimZ = .0;
                        const int NUM_GRID_X = 6;
                        const int NUM_GRID_Y = 6;
                        const int NUM_GRID_Z = 6;

                        /* Read box dimension */
                        getline(dataFile, line);
                        ssline.clear();
                        ssline.str(line);
                        ssline >> boxDimX;

                        getline(dataFile, line);
                        ssline.clear();
                        ssline.str(line);
                        ssline >> boxDimY >> boxDimY;

                        getline(dataFile, line);
                        ssline.clear();
                        ssline.str(line);
                        ssline >> boxDimZ >> boxDimZ >> boxDimZ;

                        // Create a container with the geometry given above, and make it
                        // periodic in x and y coordinates. Allocate space for
                        // eight particles within each computational block
                        container con(-boxDimX/2., boxDimX/2., -boxDimY/2., boxDimY/2., -boxDimZ/2., boxDimZ/2., 
                                      NUM_GRID_X, NUM_GRID_Y, NUM_GRID_Z,
                                      true, true, false, 8);

                        for (int iMolecule = 0; iMolecule < numUnitCellPoints; iMolecule++)
                        {
                            getline(dataFile, line); // Skip 1st C atom

                            int ix = 0, iy = 0, iz = 0;
                            double rx = 0., ry = 0., rz = 0.;
                            getline(dataFile, line);
                            ssline.clear();
                            ssline.str(line);
                            ssline >> ix >> iy >> iz;

                            rx = static_cast<double>(ix) * 500. / pow(2., 30);
                            ry = static_cast<double>(iy) * 500. / pow(2., 30);
                            rz = static_cast<double>(iz) * 500. / pow(2., 30);
                            con.put(iMolecule, rx, ry, rz);

                            /* Skip the rest atoms in the molecule */
                            for (int i = 0; i < numAtomsPerMolecule - 2; i++)
                            {
                                getline(dataFile, line);
                            }
                        }

                        /* Output volume info for each cell */
                        c_loop_all loop(con);
                        voronoicell vcell;
                        if (!loop.start())
                        {
                            cerr << "Error occurred while starting the voro cell loop.";
                            exit(1);
                        }

                        do
                        {
                            con.compute_cell(vcell, loop);
                            outFile << vcell.volume() << endl;
                        }while(loop.inc());

                        /* Skip other non Voronoi atoms */
                        for (int i = 0; i < numAtoms - numAtomsPerMolecule * numUnitCellPoints; i++)
                        {
                            getline(dataFile, line);
                        }
                    }
                }
            }
            dataFile.close();
        }
        else
        {
            cerr << "Error: unable to open file: " << *it << endl;
            exit(1);
        }
    }

    outFile.close();
    return 0;
}

