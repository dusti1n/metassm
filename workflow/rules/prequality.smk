# Rule: fastqc[Illumina, Hybrid]
rule fastqc:
    input:
        fastq="results/{project_name}/unpacked/{sample}/{sample}_{suffix}.fastq"
    output:
        html="results/{project_name}/quality/{sample}/{sample}_{suffix}_fastqc.html"
    conda:
        "../envs/prequality.yaml"
    params:
        outdir="results/{project_name}/quality/{sample}/"
    shell:
        """
        fastqc {input.fastq} --outdir={params.outdir}
        """

# Rule: multiqc[Illumina, Hybrid]
rule multiqc:
    input:
        expand("results/{project_name}/quality/{sample}/{sample}_{suffix}_fastqc.html",
               sample=sample_files.keys(),
               project_name=config["general"]["output_dir"],
               suffix=["R1", "R2"]) if config["settings"]['data_type'] in ["Illumina", "Hybrid"] else[]
    output:
        os.path.join("results",config["general"]["output_dir"],"quality/multiqc/multiqc_report.html")
    conda:
        "../envs/prequality.yaml"
    params:
        project_name=config["general"]["output_dir"]
    shell:
        """
        multiqc results/{params.project_name}/quality/ -o results/{params.project_name}/quality/multiqc/
        """

# Rule: nanoplot[Nanopore, Hybrid]
rule nanoplot:
    input:
        fastq="results/{project_name}/unpacked/{sample}/{sample}_{suffix}.fastq"
    output:
        report="results/{project_name}/quality/{sample}/nanoplot/{sample}_{suffix}_nanoplot.html"
    conda:
        "../envs/prequality.yaml"
    params:
        outdir="results/{project_name}/quality/{sample}/nanoplot/",
        prefix="{sample}_{suffix}_nanoplot"
    shell:
        """
        NanoPlot --fastq {input.fastq} \
        --outdir={params.outdir} \
        --prefix {params.prefix}
        mv {params.outdir}/{params.prefix}NanoPlot-report.html {output.report}
        """
