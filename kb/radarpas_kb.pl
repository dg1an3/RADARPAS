%% RADARPAS Knowledge Base for Prolog
%% Loads and queries RDF/Turtle knowledge from the RADARPAS source code archive
%%
%% This knowledge base uses SWI-Prolog's Semantic Web libraries to:
%% 1. Load Turtle (.ttl) files containing RDF triples
%% 2. Provide query predicates for exploring the codebase
%% 3. Support reasoning about source code structure
%%
%% Usage (SWI-Prolog):
%%   ?- [radarpas_kb].
%%   ?- load_radarpas_kb.
%%   ?- list_modules.
%%   ?- find_function(Name, Description).

:- use_module(library(semweb/rdf_db)).
:- use_module(library(semweb/turtle)).
:- use_module(library(semweb/rdf_turtle_write)).
:- use_module(library(semweb/rdfs)).

%% =============================================================================
%% Namespace Prefixes
%% =============================================================================

:- rdf_register_prefix(radar, 'http://example.org/radarpas/ontology#').
:- rdf_register_prefix(src, 'http://example.org/radarpas/source#').
:- rdf_register_prefix(dc, 'http://purl.org/dc/elements/1.1/').
:- rdf_register_prefix(dcterms, 'http://purl.org/dc/terms/').
:- rdf_register_prefix(foaf, 'http://xmlns.com/foaf/0.1/').
:- rdf_register_prefix(prov, 'http://www.w3.org/ns/prov#').
:- rdf_register_prefix(schema, 'http://schema.org/').
:- rdf_register_prefix(iao, 'http://purl.obolibrary.org/obo/IAO_').

%% =============================================================================
%% Loading the Knowledge Base
%% =============================================================================

%% load_radarpas_kb/0
%% Loads all Turtle files from the kb directory
load_radarpas_kb :-
    writeln('Loading RADARPAS Knowledge Base...'),
    load_turtle_file('ontology.ttl'),
    load_turtle_file('project.ttl'),
    load_turtle_file('modules.ttl'),
    load_turtle_file('functions.ttl'),
    load_turtle_file('types.ttl'),
    load_turtle_file('files.ttl'),
    rdf_statistics(triples(N)),
    format('Loaded ~w triples.~n', [N]).

%% load_turtle_file/1
%% Load a single Turtle file from the kb directory
load_turtle_file(FileName) :-
    format('  Loading ~w...~n', [FileName]),
    rdf_load(FileName, [format(turtle)]).

%% reload_kb/0
%% Unload and reload the knowledge base
reload_kb :-
    rdf_reset_db,
    load_radarpas_kb.

%% =============================================================================
%% Query Predicates - Modules
%% =============================================================================

%% list_modules/0
%% List all software modules in the knowledge base
list_modules :-
    format('~n=== RADARPAS Modules ===~n', []),
    forall(
        (rdf(Module, rdf:type, radar:'Module'),
         rdf(Module, rdfs:label, Label)),
        format('  ~w~n', [Label])
    ).

%% module_info/2
%% Get information about a specific module
module_info(ModuleName, Info) :-
    rdf(Module, rdfs:label, literal(ModuleName)),
    rdf(Module, rdf:type, radar:'Module'),
    findall(Prop-Value,
        (rdf(Module, Prop, Value),
         Prop \= rdf:type),
        Info).

%% find_module/2
%% Find modules matching a pattern
find_module(Pattern, Module) :-
    rdf(Module, rdf:type, radar:'Module'),
    rdf(Module, rdfs:label, Label),
    sub_atom(Label, _, _, _, Pattern).

%% module_imports/2
%% Find what a module imports
module_imports(ModuleName, ImportedModule) :-
    rdf(Module, rdfs:label, literal(ModuleName)),
    rdf(Module, radar:imports, Imported),
    rdf(Imported, rdfs:label, ImportedModule).

%% =============================================================================
%% Query Predicates - Functions and Procedures
%% =============================================================================

%% list_functions/0
%% List all functions/procedures
list_functions :-
    format('~n=== RADARPAS Functions and Procedures ===~n', []),
    forall(
        (rdf(Func, rdf:type, Type),
         (Type = radar:'Function' ; Type = radar:'Procedure'),
         rdf(Func, rdfs:label, Label)),
        format('  ~w~n', [Label])
    ).

%% find_function/2
%% Find function by name and get its description
find_function(Name, Description) :-
    rdf(Func, rdfs:label, literal(Name)),
    (rdf(Func, rdf:type, radar:'Function') ;
     rdf(Func, rdf:type, radar:'Procedure')),
    rdf(Func, dc:description, literal(Description)).

%% function_category/2
%% Find functions by category
function_category(CategoryName, FunctionName) :-
    rdf(Category, rdfs:label, literal(CategoryName)),
    rdf(Func, radar:belongsToCategory, Category),
    rdf(Func, rdfs:label, FunctionName).

%% functions_in_module/2
%% Find all functions defined in a module/file
functions_in_module(ModuleName, FunctionName) :-
    rdf(File, rdfs:label, literal(lang(_, ModuleName))),
    rdf(Func, radar:definedIn, File),
    rdf(Func, rdfs:label, FunctionName).

%% function_calls/2
%% Find what functions a function calls
function_calls(FuncName, CalledFunc) :-
    rdf(Func, rdfs:label, literal(FuncName)),
    rdf(Func, radar:calls, Called),
    rdf(Called, rdfs:label, CalledFunc).

%% =============================================================================
%% Query Predicates - Data Types
%% =============================================================================

%% list_types/0
%% List all data types
list_types :-
    format('~n=== RADARPAS Data Types ===~n', []),
    forall(
        (rdf(Type, rdf:type, TypeClass),
         rdfs:subclass_of(TypeClass, radar:'DataType'),
         rdf(Type, rdfs:label, Label)),
        format('  ~w~n', [Label])
    ).

%% type_info/2
%% Get information about a type
type_info(TypeName, Info) :-
    rdf(Type, rdfs:label, literal(TypeName)),
    findall(Prop-Value,
        rdf(Type, Prop, Value),
        Info).

%% record_fields/2
%% Get fields of a record type
record_fields(RecordName, FieldName) :-
    rdf(Record, rdfs:label, literal(RecordName)),
    rdf(Record, rdf:type, radar:'RecordType'),
    rdf(Record, radar:hasField, Field),
    rdf(Field, rdfs:label, FieldName).

%% =============================================================================
%% Query Predicates - Files
%% =============================================================================

%% list_files/0
%% List all source files
list_files :-
    format('~n=== RADARPAS Source Files ===~n', []),
    forall(
        (rdf(File, rdf:type, Type),
         rdfs:subclass_of(Type, radar:'SourceFile'),
         rdf(File, rdfs:label, Label)),
        format('  ~w~n', [Label])
    ).

%% files_by_language/2
%% Find files by programming language
files_by_language(Language, FileName) :-
    rdf(File, radar:programmingLanguage, literal(Language)),
    rdf(File, rdfs:label, FileName).

%% files_in_archive/2
%% Find files in a specific archive
files_in_archive(ArchiveName, FileName) :-
    rdf(Archive, rdfs:label, literal(ArchiveName)),
    rdf(File, radar:partOfArchive, Archive),
    rdf(File, rdfs:label, FileName).

%% pascal_files/1
%% Find all Pascal source files
pascal_files(FileName) :-
    rdf(File, rdf:type, radar:'PascalFile'),
    rdf(File, rdfs:label, FileName).

%% modula2_files/1
%% Find all Modula-2 source files
modula2_files(FileName) :-
    rdf(File, rdf:type, radar:'Modula2File'),
    rdf(File, rdfs:label, FileName).

%% =============================================================================
%% Query Predicates - Project Metadata
%% =============================================================================

%% project_info/0
%% Display project information
project_info :-
    format('~n=== RADARPAS Project Information ===~n', []),
    rdf(src:'RADARPAS', dc:title, Title),
    rdf(src:'RADARPAS', dc:description, Desc),
    format('Title: ~w~n', [Title]),
    format('Description: ~w~n', [Desc]).

%% list_versions/0
%% List all product versions
list_versions :-
    format('~n=== Product Versions ===~n', []),
    forall(
        (rdf(Version, rdf:type, radar:'ProductVersion'),
         rdf(Version, rdfs:label, Label)),
        format('  ~w~n', [Label])
    ).

%% version_info/2
%% Get information about a version
version_info(VersionName, Info) :-
    rdf(Version, rdfs:label, literal(VersionName)),
    rdf(Version, rdf:type, radar:'ProductVersion'),
    findall(Prop-Value,
        rdf(Version, Prop, Value),
        Info).

%% version_lineage/2
%% Find version derivation chain
version_lineage(VersionName, DerivedFrom) :-
    rdf(Version, rdfs:label, literal(VersionName)),
    rdf(Version, radar:derivedFrom, Parent),
    rdf(Parent, rdfs:label, DerivedFrom).

%% =============================================================================
%% Query Predicates - Functional Categories
%% =============================================================================

%% list_categories/0
%% List all functional categories
list_categories :-
    format('~n=== Functional Categories ===~n', []),
    forall(
        (rdf(Cat, rdf:type, radar:'FunctionalCategory'),
         rdf(Cat, rdfs:label, Label)),
        format('  ~w~n', [Label])
    ).

%% elements_in_category/2
%% Find all elements in a category
elements_in_category(CategoryLabel, ElementLabel) :-
    rdf(Category, rdfs:label, literal(CategoryLabel)),
    rdf(Element, radar:belongsToCategory, Category),
    rdf(Element, rdfs:label, ElementLabel).

%% =============================================================================
%% Utility Predicates
%% =============================================================================

%% describe/1
%% Get full description of any resource
describe(ResourceLabel) :-
    rdf(Resource, rdfs:label, literal(ResourceLabel)),
    format('~n=== ~w ===~n', [ResourceLabel]),
    forall(
        rdf(Resource, Prop, Value),
        format('  ~w: ~w~n', [Prop, Value])
    ).

%% search/1
%% Search for any resource containing the pattern
search(Pattern) :-
    format('~n=== Search Results for "~w" ===~n', [Pattern]),
    forall(
        (rdf(Resource, rdfs:label, Label),
         atom_string(Label, LabelStr),
         sub_string(LabelStr, _, _, _, Pattern)),
        format('  ~w~n', [Label])
    ).

%% count_by_type/0
%% Count resources by type
count_by_type :-
    format('~n=== Resource Counts by Type ===~n', []),
    findall(Type, rdf(_, rdf:type, Type), Types),
    msort(Types, SortedTypes),
    forall(
        member(T, SortedTypes),
        (aggregate_all(count, rdf(_, rdf:type, T), N),
         format('  ~w: ~w~n', [T, N]))
    ).

%% =============================================================================
%% Statistics
%% =============================================================================

%% kb_stats/0
%% Display knowledge base statistics
kb_stats :-
    format('~n=== Knowledge Base Statistics ===~n', []),
    rdf_statistics(triples(Triples)),
    format('Total triples: ~w~n', [Triples]),
    aggregate_all(count, rdf(_, rdf:type, radar:'Module'), ModCount),
    format('Modules: ~w~n', [ModCount]),
    aggregate_all(count, (rdf(_, rdf:type, T),
        (T = radar:'Function' ; T = radar:'Procedure')), FuncCount),
    format('Functions/Procedures: ~w~n', [FuncCount]),
    aggregate_all(count, (rdf(_, rdf:type, T),
        rdfs:subclass_of(T, radar:'DataType')), TypeCount),
    format('Data Types: ~w~n', [TypeCount]),
    aggregate_all(count, (rdf(_, rdf:type, T),
        rdfs:subclass_of(T, radar:'SourceFile')), FileCount),
    format('Source Files: ~w~n', [FileCount]).

%% =============================================================================
%% Interactive Help
%% =============================================================================

%% help/0
%% Display available commands
help :-
    format('~n=== RADARPAS Knowledge Base Commands ===~n~n', []),
    format('Loading:~n', []),
    format('  load_radarpas_kb     - Load the knowledge base~n', []),
    format('  reload_kb            - Reload the knowledge base~n', []),
    format('~nModules:~n', []),
    format('  list_modules         - List all modules~n', []),
    format('  module_info(Name, I) - Get module information~n', []),
    format('  find_module(Pat, M)  - Find modules matching pattern~n', []),
    format('  module_imports(M, I) - Find module imports~n', []),
    format('~nFunctions:~n', []),
    format('  list_functions       - List all functions/procedures~n', []),
    format('  find_function(N, D)  - Find function by name~n', []),
    format('  function_category(C, F) - Functions by category~n', []),
    format('  function_calls(F, C) - What a function calls~n', []),
    format('~nTypes:~n', []),
    format('  list_types           - List all data types~n', []),
    format('  type_info(Name, I)   - Get type information~n', []),
    format('  record_fields(R, F)  - Get record fields~n', []),
    format('~nFiles:~n', []),
    format('  list_files           - List all source files~n', []),
    format('  files_by_language(L, F) - Files by language~n', []),
    format('  pascal_files(F)      - List Pascal files~n', []),
    format('  modula2_files(F)     - List Modula-2 files~n', []),
    format('~nProject:~n', []),
    format('  project_info         - Show project info~n', []),
    format('  list_versions        - List product versions~n', []),
    format('  version_lineage(V, P) - Version derivation~n', []),
    format('~nUtilities:~n', []),
    format('  describe(Label)      - Describe any resource~n', []),
    format('  search(Pattern)      - Search for resources~n', []),
    format('  count_by_type        - Count resources by type~n', []),
    format('  kb_stats             - Show KB statistics~n', []),
    format('  help                 - Show this help~n', []).

%% =============================================================================
%% Auto-load on consult (optional)
%% =============================================================================

%% Uncomment to auto-load on consult:
%% :- load_radarpas_kb.
