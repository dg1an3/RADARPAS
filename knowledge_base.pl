%% ============================================================================
%% RADARPAS Knowledge Base
%% ============================================================================
%% A Prolog knowledge base asserting facts about the RADARPAS repository's
%% software modules, requirements, and relationships.
%%
%% Ontological Foundations:
%%   - Dublin Core (DC): Metadata elements for resource description
%%   - IAO (Information Artifact Ontology): Software and documentation entities
%%   - DOAP (Description of a Project): Software project vocabulary
%%   - SWO (Software Ontology): Software module relationships
%%   - SPDX: Software package data exchange
%%   - SWEET (Semantic Web for Earth and Environmental Terminology): NASA JPL
%%   - SSN/SOSA (Semantic Sensor Network): W3C sensor observations
%%   - W3C Meteorological Sensors Ontology: Weather instrument classes
%%   - ENVO (Environment Ontology): Environmental context
%%   - OM (Ontology of units of Measure): Measurement units
%%
%% Author: Generated for RADARPAS preservation project
%% Date: 2024
%% ============================================================================

:- module(radarpas_kb, [
    % Dublin Core predicates
    dc_title/2,
    dc_creator/2,
    dc_date/2,
    dc_description/2,
    dc_format/2,
    dc_identifier/2,
    dc_subject/2,
    dc_type/2,
    dc_rights/2,
    dc_language/2,
    dc_relation/3,

    % IAO predicates
    iao_is_about/2,
    iao_has_part/2,
    iao_is_specification_of/2,
    iao_denotes/2,
    iao_quality_specification/2,

    % Software module predicates
    software_module/1,
    module_purpose/2,
    module_contains_procedure/2,
    module_line_range/3,
    module_depends_on/2,

    % Procedure predicates
    procedure/1,
    procedure_purpose/2,
    procedure_category/2,
    procedure_calls/2,

    % Requirements predicates
    requirement/1,
    requirement_type/2,
    requirement_value/2,
    requirement_unit/2,
    satisfies_requirement/2,

    % Technology predicates
    technology/1,
    technology_type/2,
    technology_version/2,
    uses_technology/2,

    % File predicates
    source_file/1,
    file_path/2,
    file_line_count/2,
    file_purpose/2,
    file_contains_module/2,

    % Build system predicates
    build_artifact/1,
    build_target/2,
    build_dependency/2,
    compiler_flag/2,

    % Protocol predicates
    protocol_command/3,
    protocol_response/2,
    protocol_byte_format/2,

    % Evolution predicates
    version/1,
    version_date/2,
    version_derives_from/2,
    version_feature/2,

    % Query helpers
    all_modules/1,
    all_procedures/1,
    all_requirements/1,
    module_procedures/2,
    critical_path_modules/1,

    % SWEET Meteorology predicates
    sweet_phenomenon/2,
    sweet_realm/2,
    sweet_process/2,
    sweet_property/3,
    sweet_representation/2,

    % SSN/SOSA predicates
    sosa_sensor/1,
    sosa_observable_property/2,
    sosa_observation/3,
    sosa_actuator/1,
    sosa_actuation/3,
    sosa_platform/2,
    sosa_hosts/2,
    sosa_made_observation/2,
    ssn_system/1,
    ssn_has_subsystem/2,
    ssn_implements/2,
    ssn_deployed_on_platform/2,

    % W3C Meteorological Sensor predicates
    meteo_sensor_type/2,
    meteo_measures/2,
    meteo_unit/2,

    % ENVO Environment predicates
    envo_environment/2,
    envo_located_in/2,

    % OM Measurement predicates
    om_quantity/2,
    om_has_unit/2,
    om_has_numerical_value/2
]).

%% ============================================================================
%% DUBLIN CORE METADATA
%% ============================================================================
%% dc_* predicates follow Dublin Core Metadata Element Set (ISO 15836)

%% dc_title(Resource, Title)
%% The name given to the resource
dc_title(radarpas, 'RADARPAS - Radar Terminal System').
dc_title(radar_pas_1988, 'Original 1988 RADAR.PAS Source').
dc_title(radar_pas_modern, 'FreePascal Compatible RADAR Terminal').
dc_title(radar_control_v0, 'Program-Sliced Control Reconstruction').

%% dc_creator(Resource, Creator)
%% Entity primarily responsible for making the resource
dc_creator(radarpas, 'D. G. Lane').
dc_creator(radar_pas_1988, 'D. G. Lane').
dc_creator(ellason_e300, 'Ellason Corporation').

%% dc_date(Resource, Date)
%% Temporal coverage or creation date (ISO 8601)
dc_date(radar_pas_1988, '1988-01-14').
dc_date(radarpas_v1, '1985').
dc_date(radarpas_v2, '1987').
dc_date(radarpas_v2_1, '1988').
dc_date(gdem_v1, '1984').
dc_date(freepascal_port, '2024').

%% dc_description(Resource, Description)
%% Account of the resource
dc_description(radarpas,
    'Commercial PC-based radar terminal software for remote operation of weather radar systems via modem connection').
dc_description(radar_pas_1988,
    'Original 1894-line Turbo Pascal source code for Ellason E300/E250 Radar Terminal').
dc_description(radar_control_v0,
    'Reconstructed first-state control module using program slicing methodology').
dc_description(rs232_module,
    'Serial communication module with interrupt-driven I/O and modem protocol handling').
dc_description(graphics_module,
    'EGA graphics engine for radar image display with run-length decompression').

%% dc_format(Resource, Format)
%% File format or physical medium
dc_format(radar_pas_1988, 'text/x-pascal').
dc_format(radar_pas_modern, 'text/x-pascal').
dc_format(radarpas_binary, 'application/x-executable').
dc_format(radar_image, 'application/x-rle-encoded').

%% dc_identifier(Resource, Identifier)
%% Unambiguous reference to the resource
dc_identifier(radarpas, 'github:DLaneAtElekta/RADARPAS').
dc_identifier(radar_pas_1988, 'file:19880114 RADAR.PAS').
dc_identifier(radar_pas_modern, 'file:radar.pas').
dc_identifier(radar_control_v0, 'file:radar_control_v0.pas').

%% dc_subject(Resource, Subject)
%% Topic of the resource
dc_subject(radarpas, 'weather radar').
dc_subject(radarpas, 'remote sensing').
dc_subject(radarpas, 'telecommunications').
dc_subject(radarpas, 'embedded systems').
dc_subject(radarpas, 'real-time systems').
dc_subject(radarpas, 'software preservation').
dc_subject(radarpas, 'legacy software').

%% dc_type(Resource, Type)
%% Nature or genre of the resource (DCMI Type Vocabulary)
dc_type(radarpas, 'Software').
dc_type(radar_pas_1988, 'Software/SourceCode').
dc_type(readme_md, 'Text/Documentation').
dc_type(program_slicing_md, 'Text/Methodology').

%% dc_rights(Resource, Rights)
%% Information about rights held
dc_rights(radarpas, 'Commercial rights sold to Ellason Corporation with unlimited distribution').
dc_rights(radar_pas_1988, 'Original author retains code ownership').

%% dc_language(Resource, Language)
%% Language of the resource
dc_language(radar_pas_1988, 'Pascal').
dc_language(radar_pas_1988, 'x86 Assembly').
dc_language(radar_pas_modern, 'FreePascal').

%% dc_relation(Resource, RelationType, RelatedResource)
%% Related resources with qualified relationship
dc_relation(radar_pas_modern, 'isVersionOf', radar_pas_1988).
dc_relation(radar_control_v0, 'isDerivedFrom', radar_pas_1988).
dc_relation(radarpas, 'isPartOf', ellason_e300).
dc_relation(readme_md, 'describes', radarpas).
dc_relation(build_md, 'describes', build_system).
dc_relation(program_slicing_md, 'describes', radar_control_v0).

%% ============================================================================
%% INFORMATION ARTIFACT ONTOLOGY (IAO)
%% ============================================================================
%% IAO provides terms for information entities in scientific research

%% iao_is_about(InformationEntity, Topic)
%% What the information artifact is about
iao_is_about(radar_pas_1988, radar_control_system).
iao_is_about(radar_pas_1988, serial_communication).
iao_is_about(radar_pas_1988, ega_graphics).
iao_is_about(program_slicing_md, software_reconstruction).
iao_is_about(protocol_specification, radar_data_protocol).

%% iao_has_part(Whole, Part)
%% Compositional relationship
iao_has_part(radarpas, rs232_module).
iao_has_part(radarpas, graphics_module).
iao_has_part(radarpas, screen_module).
iao_has_part(radarpas, storage_module).
iao_has_part(radarpas, main_control_module).
iao_has_part(radarpas, initialization_module).
iao_has_part(radarpas, misc_module).
iao_has_part(radarpas, screen_dump_module).

iao_has_part(rs232_module, tx_procedure).
iao_has_part(rs232_module, rx_procedure).
iao_has_part(rs232_module, sendcom_procedure).
iao_has_part(rs232_module, setparams_procedure).
iao_has_part(rs232_module, rs232interrupt_procedure).
iao_has_part(rs232_module, initrs232_procedure).

iao_has_part(graphics_module, selectplane_procedure).
iao_has_part(graphics_module, selectfunc_procedure).
iao_has_part(graphics_module, grplot_procedure).
iao_has_part(graphics_module, grline_procedure).
iao_has_part(graphics_module, grwrite_procedure).
iao_has_part(graphics_module, displine_procedure).
iao_has_part(graphics_module, drawscale_procedure).

%% iao_is_specification_of(Specification, Implementation)
%% Normative relationship
iao_is_specification_of(protocol_specification, rs232_module).
iao_is_specification_of(graphics_specification, graphics_module).
iao_is_specification_of(system_requirements, radarpas).

%% iao_denotes(Symbol, Meaning)
%% Semantic denotation
iao_denotes(command_tilt_up, 'Increase radar antenna tilt angle').
iao_denotes(command_tilt_down, 'Decrease radar antenna tilt angle').
iao_denotes(command_range_up, 'Increase radar range setting').
iao_denotes(command_range_down, 'Decrease radar range setting').
iao_denotes(command_gain_up, 'Increase radar gain/sensitivity').
iao_denotes(command_gain_down, 'Decrease radar gain/sensitivity').
iao_denotes(q_response, 'Current radar parameter status response').

%% iao_quality_specification(QualityMeasure, Specification)
%% Quality criteria
iao_quality_specification(response_timeout, '150-300 milliseconds').
iao_quality_specification(baud_rate, '2400 bps').
iao_quality_specification(display_resolution, '640x350 pixels').
iao_quality_specification(color_depth, '16 colors').

%% ============================================================================
%% SOFTWARE MODULES
%% ============================================================================
%% Module definitions following Software Ontology (SWO) concepts

%% software_module(ModuleName)
%% Declares a software module
software_module(misc_module).
software_module(graphics_module).
software_module(screen_module).
software_module(rs232_module).
software_module(storage_module).
software_module(screen_dump_module).
software_module(initialization_module).
software_module(main_control_module).

%% module_purpose(Module, Purpose)
%% Functional description of module
module_purpose(misc_module, 'DOS interface, file operations, keyboard I/O utilities').
module_purpose(graphics_module, 'EGA graphics engine, rendering primitives, character tables').
module_purpose(screen_module, 'UI layout, range circles, map overlays, window management').
module_purpose(rs232_module, 'Serial communication, modem protocol, interrupt handling').
module_purpose(storage_module, 'Picture file management, metadata handling, retrieval').
module_purpose(screen_dump_module, 'Printer support for Epson MX80 and HP ColorJet').
module_purpose(initialization_module, 'Setup, options menu, self-modifying configuration').
module_purpose(main_control_module, 'Control loops, command processing, state machines').

%% module_contains_procedure(Module, Procedure)
%% Module-procedure membership
module_contains_procedure(rs232_module, tx).
module_contains_procedure(rs232_module, rx).
module_contains_procedure(rs232_module, reset_buf).
module_contains_procedure(rs232_module, send_com).
module_contains_procedure(rs232_module, set_params).
module_contains_procedure(rs232_module, rs232_interrupt).
module_contains_procedure(rs232_module, init_rs232).
module_contains_procedure(rs232_module, hang_up).
module_contains_procedure(rs232_module, call_station).

module_contains_procedure(graphics_module, select_plane).
module_contains_procedure(graphics_module, select_func).
module_contains_procedure(graphics_module, set_mask).
module_contains_procedure(graphics_module, gr_plot).
module_contains_procedure(graphics_module, gr_line).
module_contains_procedure(graphics_module, gr_write).
module_contains_procedure(graphics_module, gr_message).
module_contains_procedure(graphics_module, disp_line).
module_contains_procedure(graphics_module, draw_scale).
module_contains_procedure(graphics_module, window).

module_contains_procedure(screen_module, write_params).
module_contains_procedure(screen_module, write_time).
module_contains_procedure(screen_module, write_help).
module_contains_procedure(screen_module, write_gfx).
module_contains_procedure(screen_module, write_rng_mks).

module_contains_procedure(storage_module, save_pic).
module_contains_procedure(storage_module, fetch_pic).
module_contains_procedure(storage_module, insert_pic).
module_contains_procedure(storage_module, set_dta).
module_contains_procedure(storage_module, set_dir).
module_contains_procedure(storage_module, dir_entry).

module_contains_procedure(main_control_module, inter_loop).
module_contains_procedure(main_control_module, exec_com).
module_contains_procedure(main_control_module, rx_pic_loop).
module_contains_procedure(main_control_module, rx_graph_loop).
module_contains_procedure(main_control_module, read_kbd).

module_contains_procedure(initialization_module, init_system).
module_contains_procedure(initialization_module, options_menu).
module_contains_procedure(initialization_module, load_config).

module_contains_procedure(misc_module, ask).
module_contains_procedure(misc_module, gotoxy).

%% module_line_range(Module, StartLine, EndLine)
%% Source code location in original file
module_line_range(misc_module, 1, 70).
module_line_range(graphics_module, 176, 512).
module_line_range(screen_module, 513, 823).
module_line_range(rs232_module, 857, 1074).
module_line_range(storage_module, 1080, 1200).
module_line_range(main_control_module, 1689, 1894).

%% module_depends_on(DependentModule, DependencyModule)
%% Module dependency relationships
module_depends_on(main_control_module, rs232_module).
module_depends_on(main_control_module, graphics_module).
module_depends_on(main_control_module, screen_module).
module_depends_on(main_control_module, storage_module).
module_depends_on(screen_module, graphics_module).
module_depends_on(storage_module, misc_module).
module_depends_on(graphics_module, misc_module).

%% ============================================================================
%% PROCEDURES
%% ============================================================================

%% procedure(ProcedureName)
%% Declares a procedure entity
procedure(tx).
procedure(rx).
procedure(reset_buf).
procedure(send_com).
procedure(set_params).
procedure(rs232_interrupt).
procedure(init_rs232).
procedure(hang_up).
procedure(call_station).
procedure(select_plane).
procedure(select_func).
procedure(set_mask).
procedure(gr_plot).
procedure(gr_line).
procedure(gr_write).
procedure(gr_message).
procedure(disp_line).
procedure(draw_scale).
procedure(window).
procedure(write_params).
procedure(write_time).
procedure(write_help).
procedure(save_pic).
procedure(fetch_pic).
procedure(insert_pic).
procedure(inter_loop).
procedure(exec_com).
procedure(rx_pic_loop).
procedure(rx_graph_loop).

%% procedure_purpose(Procedure, Purpose)
%% Functional description
procedure_purpose(tx, 'Character transmission with handshaking').
procedure_purpose(rx, 'Non-blocking circular buffer read').
procedure_purpose(reset_buf, 'Clear and initialize receive buffer').
procedure_purpose(send_com, 'Core command send with response timeout (150-300ms)').
procedure_purpose(set_params, 'Parse Q response protocol (10-byte format)').
procedure_purpose(rs232_interrupt, 'Real-time interrupt handler for IRQ 3/4').
procedure_purpose(init_rs232, 'Initialize serial port: 2400 baud, 8N1').
procedure_purpose(hang_up, 'Terminate modem connection').
procedure_purpose(call_station, 'Dial radar station via modem').

procedure_purpose(select_plane, 'EGA plane selection via port $3C4/$3C5').
procedure_purpose(select_func, 'Bitwise function selection (AND, OR, XOR, rotation)').
procedure_purpose(gr_plot, 'Pixel-level plotting with mask operations').
procedure_purpose(gr_line, 'Bresenham-style line drawing algorithm').
procedure_purpose(gr_write, 'Character rendering with bit-shift blitting').
procedure_purpose(disp_line, 'Run-length decompression for radar data').
procedure_purpose(draw_scale, 'Range marking circles with pre-calculated tables').

procedure_purpose(write_params, 'Display current radar parameters on screen').
procedure_purpose(write_time, 'Display current time from radar response').

procedure_purpose(save_pic, 'Store received picture with metadata to disk').
procedure_purpose(fetch_pic, 'Load saved picture from disk catalog').
procedure_purpose(insert_pic, 'Time-based picture catalog sorting').

procedure_purpose(inter_loop, 'Main interactive control loop with state machine').
procedure_purpose(exec_com, 'Command processing for F1-F6 key actions').
procedure_purpose(rx_pic_loop, 'State machine for picture reception').
procedure_purpose(rx_graph_loop, 'Map overlay data reception handler').

%% procedure_category(Procedure, Category)
%% Functional categorization
procedure_category(tx, serial_io).
procedure_category(rx, serial_io).
procedure_category(reset_buf, serial_io).
procedure_category(send_com, protocol).
procedure_category(set_params, protocol).
procedure_category(rs232_interrupt, interrupt_handler).
procedure_category(init_rs232, initialization).
procedure_category(hang_up, modem_control).
procedure_category(call_station, modem_control).

procedure_category(select_plane, graphics_hardware).
procedure_category(select_func, graphics_hardware).
procedure_category(gr_plot, graphics_primitive).
procedure_category(gr_line, graphics_primitive).
procedure_category(gr_write, graphics_primitive).
procedure_category(disp_line, data_decompression).
procedure_category(draw_scale, graphics_overlay).

procedure_category(save_pic, file_io).
procedure_category(fetch_pic, file_io).
procedure_category(insert_pic, data_management).

procedure_category(inter_loop, control_flow).
procedure_category(exec_com, command_dispatch).
procedure_category(rx_pic_loop, state_machine).

%% procedure_calls(Caller, Callee)
%% Call graph relationships
procedure_calls(inter_loop, exec_com).
procedure_calls(inter_loop, send_com).
procedure_calls(inter_loop, write_params).
procedure_calls(inter_loop, rx_pic_loop).
procedure_calls(inter_loop, rx_graph_loop).

procedure_calls(exec_com, send_com).
procedure_calls(exec_com, set_params).

procedure_calls(send_com, tx).
procedure_calls(send_com, rx).
procedure_calls(send_com, reset_buf).

procedure_calls(rx_pic_loop, rx).
procedure_calls(rx_pic_loop, disp_line).
procedure_calls(rx_pic_loop, save_pic).

procedure_calls(disp_line, gr_plot).
procedure_calls(gr_line, gr_plot).
procedure_calls(gr_write, select_plane).
procedure_calls(draw_scale, gr_line).

procedure_calls(call_station, tx).
procedure_calls(call_station, init_rs232).

%% ============================================================================
%% REQUIREMENTS
%% ============================================================================
%% System requirements following quality specification patterns

%% requirement(RequirementID)
%% Declares a requirement entity
requirement(req_processor).
requirement(req_memory_min).
requirement(req_memory_rec).
requirement(req_graphics).
requirement(req_modem).
requirement(req_os).
requirement(req_storage).
requirement(req_printer).
requirement(req_baud_rate).
requirement(req_resolution).
requirement(req_colors).
requirement(req_response_time).

%% requirement_type(Requirement, Type)
%% Classification of requirement
requirement_type(req_processor, hardware).
requirement_type(req_memory_min, hardware).
requirement_type(req_memory_rec, hardware).
requirement_type(req_graphics, hardware).
requirement_type(req_modem, hardware).
requirement_type(req_os, software).
requirement_type(req_storage, hardware).
requirement_type(req_printer, peripheral).
requirement_type(req_baud_rate, performance).
requirement_type(req_resolution, display).
requirement_type(req_colors, display).
requirement_type(req_response_time, performance).

%% requirement_value(Requirement, Value)
%% Quantitative or qualitative value
requirement_value(req_processor, 'Intel 8088/8086/80286').
requirement_value(req_memory_min, 256).
requirement_value(req_memory_rec, 640).
requirement_value(req_graphics, 'EGA adapter').
requirement_value(req_modem, 'Hayes-compatible or Racal-Vadic').
requirement_value(req_os, 'MS-DOS 2.0+').
requirement_value(req_storage, 'Floppy disk (no hard drive required)').
requirement_value(req_printer, 'Epson MX80 or HP ColorJet').
requirement_value(req_baud_rate, 2400).
requirement_value(req_resolution, '640x350').
requirement_value(req_colors, 16).
requirement_value(req_response_time, 300).

%% requirement_unit(Requirement, Unit)
%% Unit of measurement
requirement_unit(req_memory_min, 'KB').
requirement_unit(req_memory_rec, 'KB').
requirement_unit(req_baud_rate, 'bps').
requirement_unit(req_colors, 'colors').
requirement_unit(req_response_time, 'ms').

%% satisfies_requirement(Component, Requirement)
%% Traceability from implementation to requirement
satisfies_requirement(rs232_module, req_modem).
satisfies_requirement(rs232_module, req_baud_rate).
satisfies_requirement(graphics_module, req_graphics).
satisfies_requirement(graphics_module, req_resolution).
satisfies_requirement(graphics_module, req_colors).
satisfies_requirement(send_com, req_response_time).
satisfies_requirement(storage_module, req_storage).
satisfies_requirement(screen_dump_module, req_printer).

%% ============================================================================
%% TECHNOLOGIES
%% ============================================================================

%% technology(TechnologyName)
%% Declares a technology entity
technology(turbo_pascal).
technology(freepascal).
technology(x86_assembly).
technology(ega_graphics).
technology(rs232_serial).
technology(dos).
technology(docker).
technology(github_actions).
technology(make).

%% technology_type(Technology, Type)
%% Classification
technology_type(turbo_pascal, programming_language).
technology_type(freepascal, programming_language).
technology_type(x86_assembly, programming_language).
technology_type(ega_graphics, graphics_standard).
technology_type(rs232_serial, communication_protocol).
technology_type(dos, operating_system).
technology_type(docker, containerization).
technology_type(github_actions, ci_cd).
technology_type(make, build_system).

%% technology_version(Technology, Version)
%% Version information
technology_version(turbo_pascal, '3.0+').
technology_version(freepascal, '3.2.0+').
technology_version(dos, '2.0+').
technology_version(docker, 'latest').

%% uses_technology(Component, Technology)
%% Technology usage relationships
uses_technology(radar_pas_1988, turbo_pascal).
uses_technology(radar_pas_1988, x86_assembly).
uses_technology(radar_pas_modern, freepascal).
uses_technology(graphics_module, ega_graphics).
uses_technology(rs232_module, rs232_serial).
uses_technology(radarpas, dos).
uses_technology(build_system, docker).
uses_technology(build_system, make).
uses_technology(ci_pipeline, github_actions).

%% ============================================================================
%% SOURCE FILES
%% ============================================================================

%% source_file(FileID)
%% Declares a source file entity
source_file(radar_pas_1988_file).
source_file(radar_pas_modern_file).
source_file(radar_control_v0_file).
source_file(dockerfile).
source_file(makefile).
source_file(build_sh).
source_file(readme_file).
source_file(build_md_file).
source_file(slicing_md_file).
source_file(github_workflow).

%% file_path(FileID, Path)
%% File system location
file_path(radar_pas_1988_file, '19880114 RADAR.PAS').
file_path(radar_pas_modern_file, 'radar.pas').
file_path(radar_control_v0_file, 'radar_control_v0.pas').
file_path(dockerfile, 'Dockerfile').
file_path(makefile, 'Makefile').
file_path(build_sh, 'build.sh').
file_path(readme_file, 'README.md').
file_path(build_md_file, 'BUILD.md').
file_path(slicing_md_file, 'PROGRAM_SLICING.md').
file_path(github_workflow, '.github/workflows/build.yml').

%% file_line_count(FileID, LineCount)
%% Source metrics
file_line_count(radar_pas_1988_file, 1894).
file_line_count(radar_pas_modern_file, 370).
file_line_count(radar_control_v0_file, 483).
file_line_count(readme_file, 350).
file_line_count(build_md_file, 161).
file_line_count(slicing_md_file, 190).

%% file_purpose(FileID, Purpose)
%% Functional description
file_purpose(radar_pas_1988_file, 'Original 1988 Turbo Pascal source with include directives').
file_purpose(radar_pas_modern_file, 'FreePascal-compatible stubbed version for modern systems').
file_purpose(radar_control_v0_file, 'Program-sliced reconstruction of first-state control').
file_purpose(dockerfile, 'Ubuntu 22.04 container with FreePascal compiler').
file_purpose(makefile, 'Build automation with compiler flags').
file_purpose(build_sh, 'Automated Docker build and run script').
file_purpose(readme_file, 'Project overview, features, architecture, history').
file_purpose(build_md_file, 'Build instructions and FreePascal notes').
file_purpose(slicing_md_file, 'Program slicing methodology documentation').
file_purpose(github_workflow, 'CI/CD pipeline for dual build testing').

%% file_contains_module(FileID, Module)
%% File-module containment
file_contains_module(radar_pas_1988_file, misc_module).
file_contains_module(radar_pas_1988_file, graphics_module).
file_contains_module(radar_pas_1988_file, screen_module).
file_contains_module(radar_pas_1988_file, rs232_module).
file_contains_module(radar_pas_1988_file, storage_module).
file_contains_module(radar_pas_1988_file, screen_dump_module).
file_contains_module(radar_pas_1988_file, initialization_module).
file_contains_module(radar_pas_1988_file, main_control_module).

file_contains_module(radar_control_v0_file, rs232_module).
file_contains_module(radar_control_v0_file, main_control_module).

%% ============================================================================
%% BUILD SYSTEM
%% ============================================================================

%% build_artifact(ArtifactName)
%% Build output entities
build_artifact(radarpas_binary).
build_artifact(object_files).
build_artifact(unit_files).
build_artifact(listing_file).
build_artifact(docker_image).

%% build_target(Makefile, Target)
%% Make targets
build_target(makefile, all).
build_target(makefile, clean).
build_target(makefile, run).
build_target(makefile, info).
build_target(makefile, help).

%% build_dependency(Target, Dependency)
%% Build dependencies
build_dependency(radarpas_binary, radar_pas_modern_file).
build_dependency(radarpas_binary, freepascal).
build_dependency(docker_image, dockerfile).
build_dependency(docker_image, radar_pas_modern_file).

%% compiler_flag(Compiler, Flag)
%% Compiler configuration
compiler_flag(freepascal, '-Mtp').      % Turbo Pascal compatibility mode
compiler_flag(freepascal, '-O2').       % Level 2 optimization
compiler_flag(freepascal, '-vh').       % Verbose with hints
compiler_flag(freepascal, '-l').        % Generate listing file

%% ============================================================================
%% PROTOCOL SPECIFICATION
%% ============================================================================

%% protocol_command(CommandName, ByteValue, Description)
%% Command protocol specification
protocol_command(tilt_up, 2, 'Increase antenna tilt angle').
protocol_command(tilt_down, 5, 'Decrease antenna tilt angle').
protocol_command(range_up, 3, 'Increase radar range').
protocol_command(range_down, 6, 'Decrease radar range').
protocol_command(gain_up, 13, 'Increase radar gain').
protocol_command(gain_down, 14, 'Decrease radar gain').
protocol_command(request_status, 81, 'Request Q status response').

%% protocol_response(ResponseName, Format)
%% Response protocol specification
protocol_response(q_response, '10-byte status packet').
protocol_response(picture_data, 'RLE-encoded radar image').
protocol_response(map_overlay, 'Geographic overlay data').

%% protocol_byte_format(ResponseName, ByteSpec)
%% Detailed byte-level specification
protocol_byte_format(q_response, byte1-identifier-'Q').
protocol_byte_format(q_response, byte2-gain_upper_nibble).
protocol_byte_format(q_response, byte3-tilt_lower_nibble_rt_flags_upper).
protocol_byte_format(q_response, byte4-range_bits_3_to_5).
protocol_byte_format(q_response, byte5-reserved).
protocol_byte_format(q_response, bytes6_9-time_ascii_hhmm).
protocol_byte_format(q_response, byte10-checksum_bytes_2_to_9).

%% ============================================================================
%% VERSION EVOLUTION
%% ============================================================================

%% version(VersionID)
%% Version entities
version(gdem_v1).
version(radarpas_v1).
version(radarpas_v2).
version(radarpas_v2_1).
version(e300rx).
version(e250term).
version(topspeed_modula2).
version(dynamic_camera).
version(erdas_plugin).
version(freepascal_port).

%% version_date(Version, Year)
%% Version chronology
version_date(gdem_v1, 1984).
version_date(radarpas_v1, 1985).
version_date(radarpas_v2, 1987).
version_date(radarpas_v2_1, 1988).
version_date(e300rx, 1990).
version_date(e250term, 1991).
version_date(dynamic_camera, 1997).
version_date(freepascal_port, 2024).

%% version_derives_from(DerivedVersion, BaseVersion)
%% Version ancestry
version_derives_from(radarpas_v1, gdem_v1).
version_derives_from(radarpas_v2, radarpas_v1).
version_derives_from(radarpas_v2_1, radarpas_v2).
version_derives_from(e300rx, radarpas_v2_1).
version_derives_from(e250term, radarpas_v2_1).
version_derives_from(topspeed_modula2, radarpas_v2_1).
version_derives_from(dynamic_camera, e300rx).
version_derives_from(erdas_plugin, dynamic_camera).
version_derives_from(freepascal_port, radarpas_v2_1).

%% version_feature(Version, Feature)
%% Notable features per version
version_feature(gdem_v1, 'Commodore BASIC implementation').
version_feature(gdem_v1, '300 lines of code').
version_feature(gdem_v1, '$200 price point').

version_feature(radarpas_v1, 'Turbo Pascal rewrite').
version_feature(radarpas_v1, 'E300PC product integration').
version_feature(radarpas_v1, '$600 price point').

version_feature(radarpas_v2, 'Save/Load picture features').
version_feature(radarpas_v2, '$800 per copy').

version_feature(radarpas_v2_1, 'Bug fixes').
version_feature(radarpas_v2_1, 'January 14, 1988 release').

version_feature(e300rx, 'Lawrenceburg TX deployment').
version_feature(e250term, 'E250 system terminal').
version_feature(topspeed_modula2, 'Language port to Modula-2').
version_feature(dynamic_camera, 'Orthorectification support').
version_feature(erdas_plugin, 'Advanced geospatial integration').
version_feature(freepascal_port, 'Modern compiler compatibility').
version_feature(freepascal_port, 'Docker containerization').

%% ============================================================================
%% DATA TYPES
%% ============================================================================

%% data_type(TypeName, Description)
%% Pascal type definitions
data_type(tilt_type, 'Byte range 0-20 for antenna tilt in degrees').
data_type(range_type, 'Byte range 0-7 for radar range setting').
data_type(gain_type, 'Byte range 0-15 for radar gain level').
data_type(time_rec, 'Record with Hour, Min, Sec, Frac fields').
data_type(register_type, 'Union type for CPU register access').
data_type(param_rec, 'Record for radar parameter storage').

%% lookup_table(TableName, Purpose, Values)
%% Pre-computed lookup tables
lookup_table(tilt_val, 'Tilt angle degrees', [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20]).
lookup_table(range_val, 'Range in kilometers', [10,25,50,75,100,125,150,200]).

%% ============================================================================
%% OPERATING MODES
%% ============================================================================

%% operating_mode(ModeName, Description)
%% System state machine modes
operating_mode(modem, 'Waiting for modem connection').
operating_mode(interactive, 'Parameter control via F1-F6 keys').
operating_mode(wait_pic, 'Waiting for picture data transmission').
operating_mode(rx_pic, 'Receiving and decompressing radar picture').
operating_mode(rx_graph, 'Receiving map overlay data').

%% mode_transition(FromMode, ToMode, Trigger)
%% State machine transitions
mode_transition(modem, interactive, 'Connection established').
mode_transition(interactive, wait_pic, 'Picture request sent').
mode_transition(wait_pic, rx_pic, 'Picture header received').
mode_transition(rx_pic, interactive, 'Picture complete').
mode_transition(interactive, rx_graph, 'Map request sent').
mode_transition(rx_graph, interactive, 'Map complete').
mode_transition(interactive, modem, 'Hang up command').

%% ============================================================================
%% HARDWARE INTERFACES
%% ============================================================================

%% hardware_port(PortAddress, Purpose)
%% Direct hardware port access
hardware_port(16#3C4, 'EGA sequencer address register').
hardware_port(16#3C5, 'EGA sequencer data register').
hardware_port(16#3CE, 'EGA graphics controller address').
hardware_port(16#3CF, 'EGA graphics controller data').
hardware_port(16#3F8, 'COM1 base address').
hardware_port(16#2F8, 'COM2 base address').

%% memory_segment(Address, Purpose)
%% Direct memory access regions
memory_segment(16#A000, 'EGA video memory base').
memory_segment(16#B800, 'Text mode video memory').

%% interrupt_vector(IRQ, Purpose)
%% Interrupt handling
interrupt_vector(3, 'COM2 serial port interrupt').
interrupt_vector(4, 'COM1 serial port interrupt').
interrupt_vector(16#10, 'BIOS video services').
interrupt_vector(16#21, 'DOS system services').

%% ============================================================================
%% SWEET - SEMANTIC WEB FOR EARTH AND ENVIRONMENTAL TERMINOLOGY
%% ============================================================================
%% NASA JPL's SWEET ontology (~6000 concepts in 200+ ontologies)
%% Provides vocabulary for earth science, meteorology, and remote sensing

%% sweet_phenomenon(PhenomenonID, Label)
%% Meteorological phenomena (SWEET Phenomena hierarchy)
sweet_phenomenon(precipitation, 'Precipitation').
sweet_phenomenon(rain, 'Rain').
sweet_phenomenon(snow, 'Snow').
sweet_phenomenon(hail, 'Hail').
sweet_phenomenon(storm, 'Storm').
sweet_phenomenon(thunderstorm, 'Thunderstorm').
sweet_phenomenon(tornado, 'Tornado').
sweet_phenomenon(hurricane, 'Hurricane').
sweet_phenomenon(weather_front, 'Weather Front').
sweet_phenomenon(cloud_formation, 'Cloud Formation').
sweet_phenomenon(fog, 'Fog').
sweet_phenomenon(wind, 'Wind').
sweet_phenomenon(radar_echo, 'Radar Echo').
sweet_phenomenon(reflectivity, 'Reflectivity').

%% sweet_realm(RealmID, Label)
%% Earth system realms (SWEET Realm hierarchy)
sweet_realm(atmosphere, 'Atmosphere').
sweet_realm(troposphere, 'Troposphere').
sweet_realm(mesosphere, 'Mesosphere').
sweet_realm(stratosphere, 'Stratosphere').
sweet_realm(hydrosphere, 'Hydrosphere').
sweet_realm(lithosphere, 'Lithosphere').
sweet_realm(planetary_boundary_layer, 'Planetary Boundary Layer').

%% sweet_process(ProcessID, Description)
%% Atmospheric processes (SWEET Process hierarchy)
sweet_process(condensation, 'Water vapor condensing to liquid').
sweet_process(evaporation, 'Liquid water becoming vapor').
sweet_process(convection, 'Vertical atmospheric motion').
sweet_process(advection, 'Horizontal transport of atmospheric properties').
sweet_process(scattering, 'Electromagnetic radiation scattering').
sweet_process(backscatter, 'Radar signal return from precipitation').
sweet_process(attenuation, 'Signal weakening through medium').
sweet_process(doppler_shift, 'Frequency change due to relative motion').

%% sweet_property(PropertyID, Label, Category)
%% Observable properties (SWEET Property hierarchy)
sweet_property(reflectivity, 'Radar Reflectivity', intensity).
sweet_property(precipitation_rate, 'Precipitation Rate', rate).
sweet_property(echo_top_height, 'Echo Top Height', spatial).
sweet_property(storm_cell_velocity, 'Storm Cell Velocity', kinematic).
sweet_property(wind_speed, 'Wind Speed', kinematic).
sweet_property(wind_direction, 'Wind Direction', orientation).
sweet_property(temperature, 'Temperature', thermodynamic).
sweet_property(humidity, 'Humidity', thermodynamic).
sweet_property(pressure, 'Atmospheric Pressure', thermodynamic).
sweet_property(visibility, 'Visibility', optical).
sweet_property(cloud_cover, 'Cloud Cover', fraction).
sweet_property(dew_point, 'Dew Point', thermodynamic).

%% sweet_representation(RepresentationID, Description)
%% Data representations (SWEET Representation hierarchy)
sweet_representation(radar_image, 'Two-dimensional radar reflectivity display').
sweet_representation(ppi_scan, 'Plan Position Indicator scan').
sweet_representation(rhi_scan, 'Range Height Indicator scan').
sweet_representation(cappi, 'Constant Altitude PPI').
sweet_representation(reflectivity_map, 'Spatial reflectivity distribution').
sweet_representation(time_series, 'Temporal sequence of observations').
sweet_representation(range_gate, 'Discrete range bin in radar data').

%% Relate RADARPAS to SWEET phenomena
radarpas_observes_phenomenon(radarpas, precipitation).
radarpas_observes_phenomenon(radarpas, storm).
radarpas_observes_phenomenon(radarpas, radar_echo).
radarpas_observes_phenomenon(radarpas, cloud_formation).

%% ============================================================================
%% SSN/SOSA - SEMANTIC SENSOR NETWORK / SENSOR OBSERVATION SAMPLE ACTUATOR
%% ============================================================================
%% W3C Recommendation for sensor and observation semantics

%% sosa_sensor(SensorID)
%% Sensors that make observations
sosa_sensor(ellason_e300_radar).
sosa_sensor(ellason_e250_radar).
sosa_sensor(radar_antenna).
sosa_sensor(radar_receiver).
sosa_sensor(radar_transmitter).

%% sosa_observable_property(PropertyID, Description)
%% Properties that can be observed
sosa_observable_property(radar_reflectivity, 'Backscattered signal intensity (dBZ)').
sosa_observable_property(antenna_tilt, 'Elevation angle of radar antenna').
sosa_observable_property(scan_range, 'Maximum observable distance').
sosa_observable_property(receiver_gain, 'Signal amplification level').
sosa_observable_property(azimuth, 'Horizontal scan position').
sosa_observable_property(range_gate_data, 'Reflectivity per range bin').
sosa_observable_property(precipitation_intensity, 'Derived rainfall rate').

%% sosa_observation(ObservationID, Property, Result)
%% Observations made by sensors
sosa_observation(obs_tilt_reading, antenna_tilt, tilt_value).
sosa_observation(obs_range_setting, scan_range, range_value).
sosa_observation(obs_gain_level, receiver_gain, gain_value).
sosa_observation(obs_picture, radar_reflectivity, rle_encoded_image).
sosa_observation(obs_timestamp, observation_time, hhmm_value).

%% sosa_actuator(ActuatorID)
%% Actuators that change observable properties
sosa_actuator(tilt_motor).
sosa_actuator(range_selector).
sosa_actuator(gain_control).
sosa_actuator(antenna_positioner).

%% sosa_actuation(ActuationID, Actuator, Property)
%% Actuations performed
sosa_actuation(act_tilt_up, tilt_motor, antenna_tilt).
sosa_actuation(act_tilt_down, tilt_motor, antenna_tilt).
sosa_actuation(act_range_up, range_selector, scan_range).
sosa_actuation(act_range_down, range_selector, scan_range).
sosa_actuation(act_gain_up, gain_control, receiver_gain).
sosa_actuation(act_gain_down, gain_control, receiver_gain).

%% sosa_platform(PlatformID, Description)
%% Platforms hosting sensors
sosa_platform(radar_station, 'Fixed ground-based radar installation').
sosa_platform(radar_tower, 'Elevated tower structure for antenna').
sosa_platform(remote_terminal, 'PC-based remote operator terminal').
sosa_platform(ellason_e300_system, 'Complete E300 radar system').
sosa_platform(ellason_e250_system, 'Complete E250 radar system').

%% sosa_hosts(Platform, Sensor)
%% Platform-sensor hosting relationship
sosa_hosts(ellason_e300_system, ellason_e300_radar).
sosa_hosts(ellason_e250_system, ellason_e250_radar).
sosa_hosts(radar_tower, radar_antenna).
sosa_hosts(radar_station, radar_receiver).
sosa_hosts(radar_station, radar_transmitter).

%% sosa_made_observation(Sensor, Observation)
%% Sensor-observation provenance
sosa_made_observation(ellason_e300_radar, obs_picture).
sosa_made_observation(ellason_e300_radar, obs_tilt_reading).
sosa_made_observation(ellason_e300_radar, obs_range_setting).
sosa_made_observation(ellason_e300_radar, obs_gain_level).
sosa_made_observation(ellason_e300_radar, obs_timestamp).

%% ssn_system(SystemID)
%% Systems composed of subsystems
ssn_system(radarpas_system).
ssn_system(radar_hardware).
ssn_system(communication_system).
ssn_system(display_system).
ssn_system(control_system).

%% ssn_has_subsystem(System, Subsystem)
%% System composition
ssn_has_subsystem(radarpas_system, radar_hardware).
ssn_has_subsystem(radarpas_system, communication_system).
ssn_has_subsystem(radarpas_system, display_system).
ssn_has_subsystem(radarpas_system, control_system).
ssn_has_subsystem(radar_hardware, radar_antenna).
ssn_has_subsystem(radar_hardware, radar_receiver).
ssn_has_subsystem(radar_hardware, radar_transmitter).
ssn_has_subsystem(communication_system, rs232_module).
ssn_has_subsystem(display_system, graphics_module).
ssn_has_subsystem(control_system, main_control_module).

%% ssn_implements(System, Procedure)
%% System-procedure implementation
ssn_implements(communication_system, send_com).
ssn_implements(communication_system, set_params).
ssn_implements(display_system, disp_line).
ssn_implements(display_system, draw_scale).
ssn_implements(control_system, inter_loop).
ssn_implements(control_system, exec_com).

%% ssn_deployed_on_platform(System, Platform)
%% Deployment relationships
ssn_deployed_on_platform(radarpas_system, remote_terminal).
ssn_deployed_on_platform(radar_hardware, radar_station).

%% ============================================================================
%% W3C METEOROLOGICAL SENSORS ONTOLOGY
%% ============================================================================
%% Based on W3C SSN extension for meteorological instruments

%% meteo_sensor_type(SensorID, TypeClass)
%% Meteorological sensor classification (W3C Meteo classes)
meteo_sensor_type(ellason_e300_radar, weather_radar).
meteo_sensor_type(ellason_e250_radar, weather_radar).
meteo_sensor_type(weather_radar, precipitation_sensor).
meteo_sensor_type(weather_radar, remote_sensing_instrument).
meteo_sensor_type(weather_radar, active_sensor).
meteo_sensor_type(weather_radar, microwave_instrument).

%% meteo_measures(SensorType, MeasurandClass)
%% What meteorological sensors measure
meteo_measures(weather_radar, precipitation).
meteo_measures(weather_radar, reflectivity).
meteo_measures(weather_radar, cloud_structure).
meteo_measures(weather_radar, storm_intensity).
meteo_measures(weather_radar, precipitation_type).
meteo_measures(weather_radar, echo_top_height).
meteo_measures(weather_radar, vertically_integrated_liquid).

%% meteo_unit(Measurand, Unit)
%% Standard meteorological units
meteo_unit(reflectivity, 'dBZ').
meteo_unit(precipitation_rate, 'mm/h').
meteo_unit(range, 'km').
meteo_unit(altitude, 'm').
meteo_unit(antenna_tilt, 'degrees').
meteo_unit(azimuth, 'degrees').
meteo_unit(temperature, 'celsius').
meteo_unit(wind_speed, 'm/s').
meteo_unit(pressure, 'hPa').

%% ============================================================================
%% ENVO - ENVIRONMENT ONTOLOGY
%% ============================================================================
%% Environmental context for observations

%% envo_environment(EnvID, Label)
%% Environmental contexts
envo_environment(terrestrial_biome, 'Terrestrial Biome').
envo_environment(atmosphere_env, 'Atmospheric Environment').
envo_environment(weather_station_env, 'Weather Station Environment').
envo_environment(radar_coverage_area, 'Radar Coverage Area').
envo_environment(precipitation_zone, 'Precipitation Zone').
envo_environment(storm_system, 'Storm System').
envo_environment(clear_air, 'Clear Air').
envo_environment(coastal_zone, 'Coastal Zone').
envo_environment(inland_zone, 'Inland Zone').

%% envo_located_in(Entity, Environment)
%% Environmental context relationships
envo_located_in(ellason_e300_system, weather_station_env).
envo_located_in(radar_station, terrestrial_biome).
envo_located_in(precipitation, atmosphere_env).
envo_located_in(storm, atmosphere_env).
envo_located_in(radar_echo, radar_coverage_area).
envo_located_in(lawrenceburg_tx_deployment, inland_zone).

%% ============================================================================
%% OM - ONTOLOGY OF UNITS OF MEASURE
%% ============================================================================
%% Standardized measurement representation

%% om_quantity(QuantityID, QuantityKind)
%% Measurable quantities
om_quantity(tilt_angle, angle).
om_quantity(scan_range_distance, length).
om_quantity(gain_level, ratio).
om_quantity(baud_rate_value, frequency).
om_quantity(response_time_duration, time).
om_quantity(pixel_resolution, length).
om_quantity(reflectivity_value, power_ratio).
om_quantity(precipitation_rate_value, speed).

%% om_has_unit(Quantity, Unit)
%% Quantity-unit associations
om_has_unit(tilt_angle, degree).
om_has_unit(scan_range_distance, kilometre).
om_has_unit(gain_level, decibel).
om_has_unit(baud_rate_value, baud).
om_has_unit(response_time_duration, millisecond).
om_has_unit(pixel_resolution, pixel).
om_has_unit(reflectivity_value, dbz).
om_has_unit(precipitation_rate_value, millimetre_per_hour).

%% om_has_numerical_value(QuantityID, Value)
%% Specific numeric values from RADARPAS
om_has_numerical_value(tilt_angle, range(0, 20)).
om_has_numerical_value(scan_range_distance, enum([10, 25, 50, 75, 100, 125, 150, 200])).
om_has_numerical_value(gain_level, range(0, 15)).
om_has_numerical_value(baud_rate_value, 2400).
om_has_numerical_value(response_time_duration, range(150, 300)).
om_has_numerical_value(pixel_resolution, dimensions(640, 350)).

%% ============================================================================
%% RADARPAS METEOROLOGICAL CONTEXT
%% ============================================================================
%% Linking RADARPAS software to meteorological domain

%% radar_band(RadarID, FrequencyBand)
%% Radar operating frequency
radar_band(ellason_e300_radar, c_band).
radar_band(ellason_e250_radar, c_band).

%% radar_application(RadarID, Application)
%% Intended use cases
radar_application(ellason_e300_radar, weather_surveillance).
radar_application(ellason_e300_radar, precipitation_monitoring).
radar_application(ellason_e300_radar, storm_tracking).
radar_application(ellason_e300_radar, aviation_weather).

%% radar_product(RadarID, ProductType, Description)
%% Data products generated
radar_product(ellason_e300_radar, base_reflectivity, 'Raw radar return intensity').
radar_product(ellason_e300_radar, composite_reflectivity, 'Maximum reflectivity in column').
radar_product(ellason_e300_radar, echo_tops, 'Height of highest detected echo').
radar_product(ellason_e300_radar, precipitation_map, 'Derived rainfall amounts').

%% coverage_pattern(RadarID, Pattern)
%% Scan strategies
coverage_pattern(ellason_e300_radar, volume_scan).
coverage_pattern(ellason_e300_radar, ppi_mode).

%% wmo_code(PhenomenonID, WMOCode, Description)
%% WMO weather code mappings (SYNOP)
wmo_code(rain, 60, 'Rain, not freezing, intermittent').
wmo_code(rain, 61, 'Rain, not freezing, continuous').
wmo_code(snow, 70, 'Snow, intermittent').
wmo_code(snow, 71, 'Snow, continuous').
wmo_code(thunderstorm, 95, 'Thunderstorm, slight or moderate').
wmo_code(thunderstorm, 97, 'Thunderstorm, heavy with hail').
wmo_code(hail, 89, 'Hail with or without thunder').

%% ============================================================================
%% QUERY HELPERS
%% ============================================================================

%% all_modules(-Modules)
%% Retrieve all software modules
all_modules(Modules) :-
    findall(M, software_module(M), Modules).

%% all_procedures(-Procedures)
%% Retrieve all procedures
all_procedures(Procedures) :-
    findall(P, procedure(P), Procedures).

%% all_requirements(-Requirements)
%% Retrieve all requirements
all_requirements(Requirements) :-
    findall(R, requirement(R), Requirements).

%% module_procedures(+Module, -Procedures)
%% Get all procedures in a module
module_procedures(Module, Procedures) :-
    findall(P, module_contains_procedure(Module, P), Procedures).

%% critical_path_modules(-Modules)
%% Modules on the critical execution path
critical_path_modules(Modules) :-
    findall(M, (
        module_depends_on(main_control_module, M) ;
        M = main_control_module
    ), Modules).

%% depends_on_transitive(+Module, -Dependency)
%% Transitive closure of module dependencies
depends_on_transitive(Module, Dep) :-
    module_depends_on(Module, Dep).
depends_on_transitive(Module, Dep) :-
    module_depends_on(Module, Intermediate),
    depends_on_transitive(Intermediate, Dep).

%% calls_transitive(+Caller, -Callee)
%% Transitive closure of procedure calls
calls_transitive(Caller, Callee) :-
    procedure_calls(Caller, Callee).
calls_transitive(Caller, Callee) :-
    procedure_calls(Caller, Intermediate),
    calls_transitive(Intermediate, Callee).

%% requirement_satisfaction_report(-Report)
%% Generate requirement traceability report
requirement_satisfaction_report(Report) :-
    findall(req(R, Type, Components), (
        requirement(R),
        requirement_type(R, Type),
        findall(C, satisfies_requirement(C, R), Components)
    ), Report).

%% version_lineage(+Version, -Lineage)
%% Get complete version ancestry
version_lineage(Version, [Version|Ancestors]) :-
    version_lineage_helper(Version, Ancestors).

version_lineage_helper(Version, []) :-
    \+ version_derives_from(Version, _), !.
version_lineage_helper(Version, [Parent|Rest]) :-
    version_derives_from(Version, Parent),
    version_lineage_helper(Parent, Rest).

%% ============================================================================
%% ONTOLOGY ALIGNMENT DOCUMENTATION
%% ============================================================================
%%
%% This knowledge base aligns with the following ontological frameworks:
%%
%% DUBLIN CORE (DC) - ISO 15836
%% - dc_title/2       -> dc:title (resource name)
%% - dc_creator/2     -> dc:creator (responsible entity)
%% - dc_date/2        -> dc:date (temporal coverage)
%% - dc_description/2 -> dc:description (resource account)
%% - dc_format/2      -> dc:format (file format/medium)
%% - dc_identifier/2  -> dc:identifier (unambiguous reference)
%% - dc_subject/2     -> dc:subject (topic)
%% - dc_type/2        -> dc:type (nature/genre)
%% - dc_rights/2      -> dc:rights (rights information)
%% - dc_language/2    -> dc:language (resource language)
%% - dc_relation/3    -> dc:relation (related resources)
%%
%% INFORMATION ARTIFACT ONTOLOGY (IAO)
%% - iao_is_about/2            -> IAO:0000136 (is about)
%% - iao_has_part/2            -> BFO:0000051 (has part)
%% - iao_is_specification_of/2 -> IAO:0000136 (specification relation)
%% - iao_denotes/2             -> IAO:0000219 (denotes)
%% - iao_quality_specification/2 -> IAO quality specification pattern
%%
%% SOFTWARE ONTOLOGY (SWO)
%% - software_module/1         -> SWO:0000001 (software)
%% - module_depends_on/2       -> SWO dependency relation
%% - uses_technology/2         -> SWO:0004000 (uses)
%%
%% DESCRIPTION OF A PROJECT (DOAP)
%% - version/1                 -> doap:Version
%% - version_derives_from/2    -> doap:revision ancestry
%%
%% SWEET - SEMANTIC WEB FOR EARTH AND ENVIRONMENTAL TERMINOLOGY (NASA JPL)
%% Reference: https://sweet.jpl.nasa.gov/
%% - sweet_phenomenon/2        -> SWEET Phenomena (weather events)
%% - sweet_realm/2             -> SWEET Realm (Earth system domains)
%% - sweet_process/2           -> SWEET Process (atmospheric processes)
%% - sweet_property/3          -> SWEET Property (observable quantities)
%% - sweet_representation/2    -> SWEET Representation (data formats)
%%
%% SSN/SOSA - W3C SEMANTIC SENSOR NETWORK
%% Reference: https://www.w3.org/TR/vocab-ssn/
%% - sosa_sensor/1             -> sosa:Sensor
%% - sosa_observable_property/2 -> sosa:ObservableProperty
%% - sosa_observation/3        -> sosa:Observation
%% - sosa_actuator/1           -> sosa:Actuator
%% - sosa_actuation/3          -> sosa:Actuation
%% - sosa_platform/2           -> sosa:Platform
%% - sosa_hosts/2              -> sosa:hosts
%% - sosa_made_observation/2   -> sosa:madeObservation
%% - ssn_system/1              -> ssn:System
%% - ssn_has_subsystem/2       -> ssn:hasSubSystem
%% - ssn_implements/2          -> ssn:implements
%% - ssn_deployed_on_platform/2 -> ssn:deployedOnPlatform
%%
%% W3C METEOROLOGICAL SENSORS ONTOLOGY
%% Reference: https://www.w3.org/2005/Incubator/ssn/ssnx/meteo/aws
%% - meteo_sensor_type/2       -> Meteorological sensor classification
%% - meteo_measures/2          -> Sensor-measurand relationship
%% - meteo_unit/2              -> Standard meteorological units
%%
%% ENVO - ENVIRONMENT ONTOLOGY
%% Reference: http://www.environmentontology.org/
%% - envo_environment/2        -> ENVO environment types
%% - envo_located_in/2         -> ENVO:located_in relationship
%%
%% OM - ONTOLOGY OF UNITS OF MEASURE
%% Reference: http://www.ontology-of-units-of-measure.org/
%% - om_quantity/2             -> om:Quantity
%% - om_has_unit/2             -> om:hasUnit
%% - om_has_numerical_value/2  -> om:hasNumericalValue
%%
%% WMO CODES
%% Reference: WMO Manual on Codes (WMO-No. 306)
%% - wmo_code/3                -> SYNOP weather present codes
%%
%% ============================================================================
%% EXAMPLE QUERIES
%% ============================================================================
%%
%% % Find all sensors and what they observe
%% ?- sosa_sensor(S), sosa_made_observation(S, Obs), sosa_observation(Obs, Prop, _).
%%
%% % Find all weather phenomena the system can observe
%% ?- radarpas_observes_phenomenon(radarpas, Phenom), sweet_phenomenon(Phenom, Label).
%%
%% % Trace module dependencies transitively
%% ?- depends_on_transitive(main_control_module, Dep).
%%
%% % Find all procedures called from the main loop
%% ?- calls_transitive(inter_loop, Proc).
%%
%% % Get version history lineage
%% ?- version_lineage(freepascal_port, Lineage).
%%
%% % Find which modules satisfy hardware requirements
%% ?- requirement_type(R, hardware), satisfies_requirement(Module, R).
%%
%% % Query meteorological sensor hierarchy
%% ?- meteo_sensor_type(ellason_e300_radar, Type), meteo_sensor_type(Type, Parent).
%%
%% % Find all SSN subsystems
%% ?- ssn_system(S), ssn_has_subsystem(S, Sub).
%%
%% ============================================================================
%% END OF KNOWLEDGE BASE
%% ============================================================================
