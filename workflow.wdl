version 1.0

workflow concat_VCFs {

    meta {
        author: "Phuwanat"
        email: "phuwanat.sak@mahidol.edu"
        description: "Concat VCFs"
    }

    parameter_meta {
        VCF_FILES: "List of VCFs to merge. Can be gzipped/bgzipped."
        TABIX_FILES: "List of VCFs to merge. Can be gzipped/bgzipped."
    }

    input {
        Array[File] VCF_FILES
        Array[File] TABIX_FILES
        String GROUP_NAME = 'samples'
    }
    call run_concating {
        input: vcf_files=VCF_FILES, tabix_files=TABIX_FILES
    }
    output {
        File concated_vcf = run_concating.vcf
        File concated_vcf_index = run_concating.vcf_index
    }
}
task run_concating {
    input {
        Array[File] vcf_files
        Array[File] tabix_files
        String group_name = 'samples'
        Int memSizeGB = 8
        Int threadCount = 2
        Int diskSizeGB = 5*round(size(vcf_files, "GB")) + 20
    }
    command <<<
        set -eux -o pipefail

        cp ~{write_lines(vcf_files)} vcf_list.txt
    
        bcftools concat -a -f vcf_list.txt --threads ~{threadCount} -Oz -o ~{group_name}.concated.vcf.gz

        ## Create index of merged VCF
        bcftools index -t -o ~{group_name}.concated.vcf.gz.tbi ~{group_name}.concated.vcf.gz
    >>>

    output {
        File vcf = "~{group_name}.concated.vcf.gz"
        File vcf_index = "~{group_name}.concated.vcf.gz.tbi"
    }

    runtime {
        memory: memSizeGB + " GB"
        cpu: threadCount
        disks: "local-disk " + diskSizeGB + " SSD"
        docker: "quay.io/biocontainers/bcftools@sha256:f3a74a67de12dc22094e299fbb3bcd172eb81cc6d3e25f4b13762e8f9a9e80aa"   # digest: quay.io/biocontainers/bcftools:1.16--hfe4b78e_1
        preemptible: 0
    }

}
