#include <argp.h> /* argument parse */
#include <iostream>
#include <vector>
#include <string>
//#include "voro++.hh"

//using namespace voro;
using namespace std;

const char* argp_program_version = "Voronoi 0.1";
const char* argp_program_bug_address = "kmtu@nmr.kuicr.kyoto-u.ac.jp";

/* Program documentation. */
static char doc[] = "Voronoi anaylsis";

/* A description of the arguments we accept. */
static char args_doc[] = "FILE...";

/* The options we understand. */
static struct argp_option options[] = {
    {"output",   'o', "FILE", 0,  "Output to FILE instead of standard output" },

    { 0 }
};

/* Used by main to communicate with parse_opt. */
struct arguments
{
//    char** strings;               /* [string...] */
    vector<string> strings;
    string output_file;            /* file arg to ‘--output’ */
};

/* Parse a single option. */
static error_t parse_opt(int key, char* arg, struct argp_state* state)
{
    /* Get the input argument from argp_parse, which we
      know is a pointer to our arguments structure. */
    struct arguments* arguments = static_cast<struct arguments*> (state->input);
//    struct arguments* arguments = (struct arguments*) (state->input);

    switch(key)
    {
    case 'o':
       arguments->output_file = arg;
       break;

//    case ARGP_KEY_NO_ARGS:
//       argp_usage (state);

    case ARGP_KEY_ARG:
       /* Here we know that state->arg_num == 0, since we
          force argument parsing to end before any more arguments can
          get here. */
//       arguments->arg1 = arg;

       /* Now we consume all the rest of the arguments.
          state->next is the index in state->argv of the
          next argument to be parsed, which is the first string
          we're interested in, so we can just use
          &state->argv[state->next] as the value for
          arguments->strings.

          In addition, by setting state->next to the end
          of the arguments, we can force argp to stop parsing here and
          return. */
//       arguments->strings = &(state->argv[state->next-1]);
       arguments->strings.push_back(state->argv[state->next - 1]);
 //      state->next = state->argc;

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

    /* Default values. */
//    arguments.strings = NULL;
///    arguments.output_file = "-";

    /* Parse our arguments; every option seen by parse_opt will be
      reflected in arguments. */
    argp_parse (&argp, argc, argv, 0, 0, &arguments);

//     error (10, 0, "ABORTED");

    if (arguments.strings.size() > 0)
    {
        cout << "STRINGS = ";
        for (vector<string>::iterator it = arguments.strings.begin();
             it != arguments.strings.end(); it++)
            cout << *it << ' ';
    }
    else
    {
        cout << "STRINGS = NULL";
    }

    cout << endl << "OUTPUT_FILE = " << arguments.output_file << endl;

    return 0;
}

