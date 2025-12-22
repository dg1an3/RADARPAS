# RADARPAS Knowledge Base

This directory contains a Prolog-accessible knowledge base representing the RADARPAS source code archive using RDF/Turtle format with standard ontologies.

## Overview

The knowledge base captures:
- **Project metadata** - Dublin Core compliant project information
- **Source code modules** - Pascal, Modula-2, and Assembly modules
- **Functions and procedures** - With descriptions, parameters, and call relationships
- **Data types** - Records, enumerations, subranges, arrays
- **File inventory** - Complete source file listing with paths and archives

## Ontologies Used

| Prefix | Ontology | Purpose |
|--------|----------|---------|
| `dc:` | Dublin Core Elements | Project metadata (title, creator, rights) |
| `dcterms:` | Dublin Core Terms | Extended metadata (created, modified) |
| `foaf:` | Friend of a Friend | Author/creator information |
| `iao:` | Information Artifact Ontology | Document classification |
| `prov:` | W3C Provenance | Version lineage and derivation |
| `schema:` | Schema.org | Software application properties |
| `radar:` | RADARPAS Ontology | Custom source code vocabulary |
| `src:` | RADARPAS Source | Instance data namespace |

## Files

| File | Description |
|------|-------------|
| `ontology.ttl` | Custom ontology for source code representation |
| `project.ttl` | Project metadata, versions, and archives |
| `modules.ttl` | Software modules and their relationships |
| `functions.ttl` | Procedures, functions, and their properties |
| `types.ttl` | Data types, records, constants |
| `files.ttl` | Source file inventory with paths |
| `radarpas_kb.pl` | Prolog interface for querying |

## Usage with SWI-Prolog

```prolog
% Load the knowledge base
?- [radarpas_kb].
?- load_radarpas_kb.

% Show available commands
?- help.

% List all modules
?- list_modules.

% Find functions by name
?- find_function('InitEGA', Description).

% Find functions in a category
?- function_category('Graphics & Display', FuncName).

% List Pascal files
?- pascal_files(FileName).

% Get version lineage
?- version_lineage('E300PC 3.1', Parent).

% Show statistics
?- kb_stats.
```

## Custom Ontology Classes

### Source Code Elements
- `radar:SoftwareProject` - Top-level project
- `radar:Module` - A compilation unit
- `radar:Program` - Main executable
- `radar:Unit` - Library unit
- `radar:Library` - Reusable module collection

### Code Elements
- `radar:Callable` - Functions and procedures
- `radar:Function` - Returns a value
- `radar:Procedure` - No return value
- `radar:InterruptHandler` - ISR

### Data Types
- `radar:DataType` - Base type class
- `radar:RecordType` - Structured data
- `radar:EnumerationType` - Enumerated values
- `radar:SubrangeType` - Bounded integers
- `radar:ArrayType` - Indexed collections
- `radar:PointerType` - Memory addresses

### Files
- `radar:SourceFile` - Any source file
- `radar:PascalFile` - Pascal source (.PAS, .RDR)
- `radar:Modula2File` - Modula-2 source (.MOD)
- `radar:AssemblyFile` - Assembly source (.ASM)
- `radar:DefinitionFile` - Interface definitions (.DEF)

### Metadata
- `radar:ProductVersion` - Release version
- `radar:Archive` - Dated source archive
- `radar:FunctionalCategory` - Code categorization

## Key Properties

- `radar:definedIn` - Links element to source file
- `radar:imports` - Module dependencies
- `radar:calls` - Function call relationships
- `radar:partOfVersion` - Version membership
- `radar:partOfArchive` - Archive membership
- `radar:belongsToCategory` - Functional classification
- `radar:hasField` - Record fields
- `radar:hasParameter` - Function parameters
- `radar:lineNumber` - Source location

## Example Queries

### Find all graphics functions
```prolog
?- function_category('Graphics & Display', F).
```

### Trace version history
```prolog
?- version_lineage('E300PC 3.1', V1), version_lineage(V1, V2).
```

### Find functions that call a specific function
```prolog
?- function_calls(Caller, 'InitEGA').
```

### List Modula-2 modules with their descriptions
```prolog
?- rdf(M, rdf:type, radar:'Modula2File'),
   rdf(M, rdfs:label, Name),
   rdf(M, dc:description, Desc).
```

## Extending the Knowledge Base

To add new facts, create additional `.ttl` files following the same patterns:

```turtle
@prefix radar: <http://example.org/radarpas/ontology#> .
@prefix src: <http://example.org/radarpas/source#> .
@prefix dc: <http://purl.org/dc/elements/1.1/> .

src:MyNewModule a radar:Module ;
    rdfs:label "MYMOD" ;
    dc:description "Description of the module" ;
    radar:programmingLanguage "Modula-2" .
```

Then update `radarpas_kb.pl` to load the new file.
