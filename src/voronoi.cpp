#include <argp.h> /* argument parse */
#include <iostream> /* cin cout cerr */
#include <fstream>
#include <vector>
#include <string>
#include <cstdlib> /* exit() */
#include <sstream> /* stringstream */
//#include "voro++.hh"

//using namespace voro;
using namespace std;


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

int main(int argc, char** argv) {
    struct arguments arguments;
    string line;

    /* Default values for arguments*/
    arguments.outFilename = "voronoi.out";

    /* Parse our arguments; every option seen by parse_opt will be
      reflected in arguments. */
    argp_parse (&argp, argc, argv, 0, 0, &arguments);

    /* Show the parsed arguments on the screen */
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
    
    /* Iterate and open each dataFile */
    stringstream* pssline;
    for (vector<string>::iterator it = arguments.dataFilenames.begin();
         it != arguments.dataFilenames.end(); it++)
    {
        ifstream dataFile(it->c_str());
        if (dataFile.is_open())
        {
            cout << "Reading " << *it << " ..." << endl;
            while (dataFile.good())
            {
                /* Read and process dataFile */
                getline(dataFile, line);
                pssline = new stringstream(line);
                // *pssline >> var1 >> var2
                cout << pssline->str() << endl;
                delete pssline;
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

