# Rule: cutadapt[Illumina, Hybrid]
rule cutadapt:
    input:
        r1="results/{project_name}/unpacked/{sample}/{sample}_R1.fastq",
        r2="results/{project_name}/unpacked/{sample}/{sample}_R2.fastq"
    output:
        trimmed_r1="results/{project_name}/filtered/cutadapt/{sample}/{sample}_R1_trimmed.fastq",
        trimmed_r2="results/{project_name}/filtered/cutadapt/{sample}/{sample}_R2_trimmed.fastq"
    conda:
        "../envs/prepolish.yaml"
    params:
        adapter_r1=config["cutadapt"]["adapter_r1"],
        adapter_r2=config["cutadapt"]["adapter_r2"],
        min_length=config["cutadapt"]["min_length"]
    shell:
        """
        cutadapt \
            -a {params.adapter_r1} \
            -A {params.adapter_r2} \
            --minimum-length {params.min_length} \
            -o {output.trimmed_r1} \
            -p {output.trimmed_r2} \
            {input.r1} \
            {input.r2} \
        """

# Rule: porechop[Nanopore, Hybrid]
rule porechop:
    input:
        ont="results/{project_name}/unpacked/{sample}/{sample}_{suffix}.fastq"
    output:
        trimmed_ont="results/{project_name}/filtered/porechop/{sample}/{sample}_{suffix}_trimmed.fastq"
    conda:
        "../envs/prepolish.yaml"
    shell:
        """
        porechop \
            -i {input.ont} \
            -o {output.trimmed_ont}
        """
