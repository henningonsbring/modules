process METAMAPS_MAPDIRECTLY {
    tag "$meta.id"
    label 'process_low'

    conda (params.enable_conda ? "bioconda::metamaps=0.1.98102e9" : null)
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/metamaps:0.1.98102e9--h176a8bc_0':
        'quay.io/biocontainers/metamaps:0.1.98102e9--h176a8bc_0' }"

    input:
    tuple val(meta), path(reads)
    path database

    output:
    tuple val(meta), path("*classification_res")                          , emit: classification_res
     path("*classification_res.meta")                        , emit: meta_file
     path("*classification_res.meta.unmappedReadsLengths")   , emit: meta_unmappedreadsLengths
     path("*classification_res.parameters")                  , emit: para_file
    path "versions.yml"                                                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    metamaps \\
        mapDirectly \\
        $args \\
        --all \\
        --reference $database \\
        --threads $task.cpus \\
        --query $reads \\
        --output ${prefix}.classification_res

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        metamaps: \$(metamaps | sed -n 2p | sed 's/^.*MetaMaps v //')
    END_VERSIONS
    """
}
