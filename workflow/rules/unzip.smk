# Rule: unzip[Illumina, Nanopore, Hybrid]
rule unzip:
    input:
        gzipped=lambda wildcards: sample_files[wildcards.sample].get(
            {"R1": "fq1", "R2": "fq2", "ONT": "ONT"}[wildcards.suffix]
        )
    output:
        unzipped="results/{project_name}/unpacked/{sample}/{sample}_{suffix}.fastq"
    conda:
        "../envs/unzip.yaml"
    shell:
        """
        pigz -d -c {input.gzipped} > {output.unzipped}
        """
