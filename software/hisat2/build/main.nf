// Import generic module functions
include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

def VERSION = '2.2.0'

process HISAT2_BUILD {
    tag "$fasta"
    label 'process_high'
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), publish_id:'') }

    conda (params.enable_conda ? "bioconda::hisat2=2.2.0" : null)
    if (workflow.containerEngine == 'singularity' && !params.singularity_pull_docker_container) {
        container "https://depot.galaxyproject.org/singularity/hisat2:2.2.0--py37hfa133b6_4"
    } else {
        container "quay.io/biocontainers/hisat2:2.2.0--py37hfa133b6_4"
    }

    input:
    path fasta
    path gtf
    path splicesites

    output:
    path "hisat2",        emit: index
    path "*.version.txt", emit: version

    script:
    def avail_mem = 0
    if (!task.memory) {
        log.info "[HISAT2 index build] Available memory not known - defaulting to 0. Specify process memory requirements to change this."
    } else {
        log.info "[HISAT2 index build] Available memory: ${task.memory}"
        avail_mem = task.memory.toGiga()
    }

    def extract_exons = ''
    def ss = ''
    def exon = ''
    if (avail_mem > params.hisat_build_memory) {
        log.info "[HISAT2 index build] Over ${params.hisat_build_memory} GB available, so using splice sites and exons in HISAT2 index"
        extract_exons = "hisat2_extract_exons.py $gtf > ${gtf.baseName}.exons.txt"
        ss = "--ss $splicesites"
        exon = "--exon ${gtf.baseName}.exons.txt"
    } else {
        log.info "[HISAT2 index build] Less than ${params.hisat_build_memory} GB available, so NOT using splice sites and exons in HISAT2 index."
        log.info "[HISAT2 index build] Use --hisat_build_memory [small number] to skip this check."
    }

    def software = getSoftwareName(task.process)
    """
    mkdir hisat2
    $extract_exons
    hisat2-build \\
        -p $task.cpus \\
        $ss \\
        $exon \\
        $options.args \\
        $fasta \\
        hisat2/${fasta.baseName}

    echo $VERSION > ${software}.version.txt
    """
}
