version 1.0

workflow DeNovoCNN{
	meta {
		description: " DeNovoCNN is a combination of three models for the calling of substitution, deletion and insertion DNMs"
	}
	input {
		String WORKING_DIRECTORY
		File CHILD_VCF
		File FATHER_VCF
		File MOTHER_VCF
		File CHILD_BAM
		File FATHER_BAM
		File MOTHER_BAM
		File CHILD_BAM_INDEX
		File FATHER_BAM_INDEX
		File MOTHER_BAM_INDEX
		String SNP_MODEL
		String INSERTION_MODEL
		String DELETION_MODEL
		File REFERENCE_GENOME
		File REFERENCE_GENOME_INDEX
		String OUTFILE_NAME
		
		String docker
		Int NUM_THREAD
		Int MEMORY
		Int DISK
	
	}
	
	call DenovoCNN {
		input:
			WORKING_DIRECTORY = WORKING_DIRECTORY,
			CHILD_VCF = CHILD_VCF,
			FATHER_VCF = FATHER_VCF,
			MOTHER_VCF = MOTHER_VCF,
			CHILD_BAM = CHILD_BAM,
			FATHER_BAM = FATHER_BAM,
			MOTHER_BAM = MOTHER_BAM,
			CHILD_BAM_INDEX = CHILD_BAM_INDEX,
			FATHER_BAM_INDEX = FATHER_BAM_INDEX,
			MOTHER_BAM_INDEX = MOTHER_BAM_INDEX,
			SNP_MODEL = SNP_MODEL,
			INSERTION_MODEL =INSERTION_MODEL,
			DELETION_MODEL = DELETION_MODEL,
			REFERENCE_GENOME = REFERENCE_GENOME,
			REFERENCE_GENOME_INDEX = REFERENCE_GENOME_INDEX,
			OUTFILE_NAME = OUTFILE_NAME,
			
			docker = docker,
			NUM_THREAD = NUM_THREAD,
			MEMORY = MEMORY,
			DISK = DISK
		
		}


	## workflow output
	output {
		File output_vcf=DenovoCNN.output_vcf
	}	

}



task DenovoCNN {
	input {
		String WORKING_DIRECTORY
		File CHILD_VCF
		File FATHER_VCF
		File MOTHER_VCF
		File CHILD_BAM
		File FATHER_BAM
		File MOTHER_BAM
		File CHILD_BAM_INDEX
		File FATHER_BAM_INDEX
		File MOTHER_BAM_INDEX
		String SNP_MODEL
		String INSERTION_MODEL
		String DELETION_MODEL
		File REFERENCE_GENOME
		File REFERENCE_GENOME_INDEX
		String OUTFILE_NAME
		
		String docker
		Int NUM_THREAD
		Int MEMORY
		Int DISK
	
	}
	command {
	set -e
	ulimit -n 100000
	bash /app/apply_denovocnn.sh \
		-w=${WORKING_DIRECTORY} \
		--child-vcf=${CHILD_VCF} \
		--father-vcf=${FATHER_VCF} \
		--mother-vcf=${MOTHER_VCF} \
		--child-bam=${CHILD_BAM} \
		--father-bam=${FATHER_BAM} \
		--mother-bam=${MOTHER_BAM} \
		--snp-model=${SNP_MODEL} \
		--in-model=${INSERTION_MODEL} \
		--del-model=${DELETION_MODEL} \
		--genome=${REFERENCE_GENOME} \
		--output=${OUTFILE_NAME}_predictions.csv
	}
	runtime {
		docker: "${docker}"
		cpu: "${NUM_THREAD}"
		memory: "${MEMORY} GB"
		disk: "${DISK} GB"
	}
	output {
		File output_vcf="${WORKING_DIRECTORY}/${OUTFILE_NAME}_predictions.csv"
	}
}
