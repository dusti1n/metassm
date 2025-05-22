# Rule: asmbflye[Nanopore, Hybrid]
rule asmbflye:
    input:
        trimmed_ont="results/{project_name}/filtered/porechop/{sample}/{sample}_{suffix}_trimmed.fastq"
    output:
        assembly_flye="results/{project_name}/assembles/flye/{sample}/{sample}_{suffix}_asmb.fasta"
    conda:
        "../envs/asmbflye.yaml"
    params:
        flye_dir="results/{project_name}/assembles/flye/{sample}/",
        genome_size=config["settings"]["genome_size"],
        iterations=config["assembler"]["flye"]["iterations"],
        threads=config["settings"]["threads"]
    shell:
        """
        flye --nano-raw {input.trimmed_ont} \
             --out-dir {params.flye_dir} \
             --genome-size {params.genome_size} \
             --iterations {params.iterations} \
             --threads {params.threads}
        
        mv {params.flye_dir}/assembly.fasta {output.assembly_flye}
        """

# Rule: asmbcanu[Nanopore, Hybrid]
rule asmbcanu:
    input:
        trimmed_ont="results/{project_name}/filtered/porechop/{sample}/{sample}_{suffix}_trimmed.fastq"
    output:
        assembly_canu="results/{project_name}/assembles/canu/{sample}/{sample}_{suffix}.contigs.fasta"
    conda:
        "../envs/asmbcanu.yaml"
    params:
        canu_dir="results/{project_name}/assembles/canu/{sample}/",
        prefix="{sample}_{suffix}",
        genome_size=config["settings"]["genome_size"],
        low_coverage=config["assembler"]["canu"]["stop_on_low_coverage"],
        min_coverage=config["assembler"]["canu"]["min_input_coverage"],
    threads: config["settings"]["threads"]
    shell:
        """
        canu -p {params.prefix} -d {params.canu_dir} \
            genomeSize={params.genome_size} \
            -nanopore {input.trimmed_ont} \
            useGrid=false \
            stopOnLowCoverage={params.low_coverage} \
            minInputCoverage={params.min_coverage}
        """

# Rule: asmbshasta[Nanopore, Hybrid]
rule asmbshasta:
    input:
        trimmed_ont="results/{project_name}/filtered/porechop/{sample}/{sample}_{suffix}_trimmed.fastq"
    output:
        assembly_shasta="results/{project_name}/assembles/shasta/{sample}/{sample}_{suffix}_asmb.fasta"
    conda:
        "../envs/asmbshasta.yaml"
    params:
        shasta_dir="results/{project_name}/assembles/shasta/{sample}",
        prefix="{sample}_{suffix}",
        genome_size=config["settings"]["genome_size"],
    threads: config["settings"]["threads"]
    shell:
        """
        shasta --input {input.trimmed_ont} \
            --assemblyDirectory {params.shasta_dir} \
            --threads {threads} \
            --memoryBacking disk \
            --memoryMode filesystem \
            --config Nanopore-May2022
        
        mv {params.shasta_dir}/Assembly.fasta {output.assembly_shasta}
        """

# Rule: asmbswtdbg2[Nanopore, Hybrid]
rule asmbswtdbg2:
    input:
        trimmed_ont="results/{project_name}/filtered/porechop/{sample}/{sample}_{suffix}_trimmed.fastq"
    output:
        assembly_wtdbg2="results/{project_name}/assembles/wtdbg2/{sample}/{sample}_{suffix}_asmb.fasta"
    conda:
        "../envs/asmbwtdbg2.yaml"
    params:
        wtdbg2_dir="results/{project_name}/assembles/wtdbg2/{sample}",
        prefix="{sample}_{suffix}",
        genome_size=config["settings"]["genome_size"],
        threads=config["settings"]["threads"],
    threads: config["settings"]["threads"]
    shell:
        """
        mkdir -p {params.wtdbg2_dir}
        wtdbg2 -x ont -g {params.genome_size} -t {threads} -i {input.trimmed_ont} -fo {params.wtdbg2_dir}/{params.prefix}
        wtpoa-cns -t {threads} -i {params.wtdbg2_dir}/{params.prefix}.ctg.lay.gz -fo {output.assembly_wtdbg2}
        """

# Rule: asmbspades[Illumina, Hybrid]
rule asmbspades:
    input:
        trimmed_r1="results/{project_name}/filtered/cutadapt/{sample}/{sample}_R1_trimmed.fastq",
        trimmed_r2="results/{project_name}/filtered/cutadapt/{sample}/{sample}_R2_trimmed.fastq",
        trimmed_ont="results/{project_name}/filtered/porechop/{sample}/{sample}_ONT_trimmed.fastq" if config["settings"]["data_type"] == "Hybrid" else[]
    output:
        assembly_spades="results/{project_name}/assembles/spades/{sample}/{sample}_asmb.fasta"
    conda:
        "../envs/asmbspades.yaml"
    params:
        data_type=config["settings"]["data_type"],
        spades_dir="results/{project_name}/assembles/spades/{sample}",
    threads: config["settings"]["threads"]
    shell:
        """
        mkdir -p {params.spades_dir}

        if [[ "{params.data_type}" == "Hybrid" && -s "{input.trimmed_ont}" ]]; then
            echo "INFO: Running HybridSPAdes (Illumina + Nanopore)"
            spades.py --nanopore {input.trimmed_ont} \
                      -1 {input.trimmed_r1} -2 {input.trimmed_r2} \
                      --isolate -o {params.spades_dir} --threads {threads}
        else
            echo "INFO: Running SPAdes in Illumina-Only Mode"
            spades.py -1 {input.trimmed_r1} -2 {input.trimmed_r2} \
                      --isolate -o {params.spades_dir} --threads {threads}
        fi

        mv {params.spades_dir}/contigs.fasta {output.assembly_spades}
        """
