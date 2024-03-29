#
# Copyright (C) 2014 Digia Plc
#
# All rights reserved
#

include(CMakeParseArguments)

function(QTQUICK_COMPILER_DETERMINE_OUTPUT_FILENAME outvariable filename)
    file(RELATIVE_PATH relpath ${CMAKE_CURRENT_SOURCE_DIR} ${filename})
    string(REPLACE ".qml" "_qml" relpath ${relpath})
    string(REPLACE ".js" "_js" relpath ${relpath})
    string(REPLACE "/" "_" relpath ${relpath})
    set(${outvariable} ${CMAKE_CURRENT_BINARY_DIR}/${relpath}.cpp PARENT_SCOPE)
endfunction()

function(QTQUICK_COMPILER_ADD_RESOURCES outfiles)
    set(options)
    set(oneValueArgs)
    set(multiValueArgs OPTIONS)

    cmake_parse_arguments(_RCC "${options}" "${oneValueArgs}" "${multiValueArgs}" ${ARGN})

    find_package(Qt5 COMPONENTS Qml Core)

    set(compiler_path "${_qt5Core_install_prefix}/bin/qtquickcompiler")

    get_target_property(rcc_path ${Qt5Core_RCC_EXECUTABLE} IMPORTED_LOCATION)

    set(rcc_files ${_RCC_UNPARSED_ARGUMENTS})
    set(rcc_options ${_RCC_OPTIONS})
    set(filtered_rcc_files)
    set(compiler_output)
    set(rcc_files_with_compilation_units)
    set(loader_flags)

    foreach(_resource ${rcc_files})
        get_filename_component(resource_base ${_resource} NAME_WE)
        set(new_resource_file ${CMAKE_CURRENT_BINARY_DIR}/${resource_base}_qtquickcompiler.qrc)

        get_filename_component(input_resource ${_resource} ABSOLUTE)

        execute_process(COMMAND ${compiler_path} -filter-resource-file ${input_resource} ${new_resource_file} OUTPUT_VARIABLE remaining_files)
        if(remaining_files)
            list(APPEND filtered_rcc_files ${new_resource_file})
            list(APPEND loader_flags "--resource-file-mapping=${_resource}=${new_resource_file}")
        else()
            list(APPEND loader_flags "--resource-file-mapping=${_resource}")
        endif()

        set(rcc_file_with_compilation_units)

        exec_program(${rcc_path} ARGS -list ${input_resource} OUTPUT_VARIABLE rcc_contents)
        string(REGEX REPLACE "[\r\n]+" ";" rcc_contents ${rcc_contents})
        foreach(it ${rcc_contents})
            get_filename_component(extension ${it} EXT)
            if("x${extension}" STREQUAL "x.qml" OR "x${extension}" STREQUAL "x.js" OR "x${extension}" STREQUAL "x.ui.qml")
                qtquick_compiler_determine_output_filename(output_file ${it})
                add_custom_command(OUTPUT ${output_file} COMMAND ${compiler_path} ARGS --resource=${input_resource} ${it} ${output_file} DEPENDS ${it})
                list(APPEND compiler_output ${output_file})
                set(rcc_file_with_compilation_units ${input_resource})
            endif()
        endforeach()

        if(rcc_file_with_compilation_units)
            list(APPEND rcc_files_with_compilation_units ${rcc_file_with_compilation_units})
        endif()
    endforeach()

    if(rcc_files_with_compilation_units)
        set(loader_source ${CMAKE_CURRENT_BINARY_DIR}/qtquickcompiler_loader.cpp)
        add_custom_command(OUTPUT ${loader_source} COMMAND ${compiler_path} ARGS ${loader_flags} ${rcc_files_with_compilation_units} ${loader_source} DEPENDS ${rcc_files_with_compilation_units})
        list(APPEND compiler_output ${loader_source})
    endif()

    qt5_add_resources(output_resources ${filtered_rcc_files} OPTIONS ${options})
    set(${outfiles} ${output_resources} ${compiler_output} PARENT_SCOPE)

    include_directories(${Qt5Qml_PRIVATE_INCLUDE_DIRS})
endfunction()

