version 1.0

workflow DeNovoCNN{
	meta {
		description: " DeNovoCNN is a combination of three models for the calling of substitution, deletion and insertion DNMs"
	}
	input {
		Array[String] CSVList
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
	
	## split bam by chromosome 
	scatter (CHR in CSVList) {
		call SplitBAM {
			input:
				samplenam = OUTFILE_NAME,
				CHR = CHR,
				MOTHER_BAM = MOTHER_BAM,
				MOTHER_BAM_INDEX = MOTHER_BAM_INDEX,
				FATHER_BAM = FATHER_BAM,
				FATHER_BAM_INDEX =FATHER_BAM_INDEX,
				CHILD_BAM = CHILD_BAM,
				CHILD_BAM_INDEX = CHILD_BAM_INDEX,
				
				NUM_THREAD = NUM_THREAD,
				MEMORY = MEMORY,
				DISK = DISK		
		}
		
		# split VCF
		call SplitVCF {
			input:
				samplenam = OUTFILE_NAME,
				CHR = CHR,

				MOTHER_VCF = MOTHER_VCF,
				FATHER_VCF = FATHER_VCF,
				CHILD_VCF = CHILD_VCF

		}
	
		## call denovoCNN per chromosome
			call denovoCNN {
				input:
					CHR = CHR,
					WORKING_DIRECTORY = WORKING_DIRECTORY,
					CHILD_VCF = SplitVCF.CHILD_VCF_CHR,
					FATHER_VCF = SplitVCF.FATHER_VCF_CHR,
					MOTHER_VCF = SplitVCF.MOTHER_VCF_CHR,
					CHILD_BAM = SplitBAM.CHILD_BAM_CHR,
					FATHER_BAM = SplitBAM.FATHER_BAM_CHR,
					MOTHER_BAM = SplitBAM.MOTHER_BAM_CHR,
					CHILD_BAM_INDEX = SplitBAM.CHILD_BAM_CHR_BAI,
					FATHER_BAM_INDEX = SplitBAM.FATHER_BAM_CHR_BAI,
					MOTHER_BAM_INDEX = SplitBAM.MOTHER_BAM_CHR_BAI,
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
		
	}
	
	
	## combine all chromosome
	call MergeCSV {
	input:
		CSVList = denovoCNN.output_vcf,
		samplenam = OUTFILE_NAME
	}
	
	


	## workflow output
	output {
		File output_vcf=MergeCSV.Prediction_output
	}	

}


## split bam by chromosome
task SplitBAM {
	input {
		String samplenam
		String CHR
		File MOTHER_BAM
		File MOTHER_BAM_INDEX
		File FATHER_BAM
		File FATHER_BAM_INDEX
		File CHILD_BAM
		File CHILD_BAM_INDEX
		
		Int NUM_THREAD
		Int MEMORY
		Int DISK
	}
	
	command {
		set -e
		
		# extact chromosome bam from bam
		samtools view -b ${MOTHER_BAM} -@ ${NUM_THREAD} ${CHR} | samtools sort -@ ${NUM_THREAD} > ${samplenam}_MOT_${CHR}.sorted.bam
		samtools index -@ ${NUM_THREAD} ${samplenam}_MOT_${CHR}.sorted.bam	
		
		samtools view -b ${FATHER_BAM} -@ ${NUM_THREAD} ${CHR} | samtools sort -@ ${NUM_THREAD} > ${samplenam}_FAT_${CHR}.sorted.bam
		samtools index -@ ${NUM_THREAD} ${samplenam}_FAT_${CHR}.sorted.bam
		
		samtools view -b ${CHILD_BAM} -@ ${NUM_THREAD} ${CHR} | samtools sort -@ ${NUM_THREAD} > ${samplenam}_CHI_${CHR}.sorted.bam
		samtools index -@ ${NUM_THREAD} ${samplenam}_CHI_${CHR}.sorted.bam
		
	}
	
	runtime {
		docker: "staphb/samtools:latest"
		cpu: "${NUM_THREAD}"
		memory: "${MEMORY} GB"
		disk: "${DISK} GB"
	}
	
	output {
		File MOTHER_BAM_CHR="${samplenam}_MOT_${CHR}.sorted.bam"
		File MOTHER_BAM_CHR_BAI="${samplenam}_MOT_${CHR}.sorted.bam.bai"
		
		File FATHER_BAM_CHR="${samplenam}_FAT_${CHR}.sorted.bam"
		File FATHER_BAM_CHR_BAI="${samplenam}_FAT_${CHR}.sorted.bam.bai"
		
		File CHILD_BAM_CHR="${samplenam}_CHI_${CHR}.sorted.bam"
		File CHILD_BAM_CHR_BAI="${samplenam}_CHI_${CHR}.sorted.bam.bai"
			
	}

}



## split vcf by chromosome
task SplitVCF {
	input {
		String samplenam
		String CHR
		
		File MOTHER_VCF
		File FATHER_VCF
		File CHILD_VCF
	}
	
	command {
		set -e
		
		# split vcf.gz per chromosome, and generate vcf file 
		vcftools --gzvcf ${MOTHER_VCF} --chr ${CHR}  --recode --out ${samplenam}_MOT_${CHR}
		vcftools --gzvcf ${FATHER_VCF} --chr ${CHR}  --recode --out ${samplenam}_FAT_${CHR}
		vcftools --gzvcf ${CHILD_VCF} --chr ${CHR}  --recode --out ${samplenam}_CHI_${CHR}
		
	}
	
	runtime {
		docker: "biocontainers/vcftools:v0.1.16-1-deb_cv1"
		cpu: 5
		memory: "40 GB"
		disk: "100 GB"
	}
	
	output {
		
		File CHILD_VCF_CHR="${samplenam}_CHI_${CHR}.recode.vcf"
		File MOTHER_VCF_CHR="${samplenam}_MOT_${CHR}.recode.vcf"
		File FATHER_VCF_CHR="${samplenam}_FAT_${CHR}.recode.vcf"
			
	}

}


task denovoCNN {
	input {
		String? CHR
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
		--output=${OUTFILE_NAME}_predictions${CHR}.csv
	}
	runtime {
		docker: "${docker}"
		cpu: "${NUM_THREAD}"
		memory: "${MEMORY} GB"
		disk: "${DISK} GB"
	}
	output {
		File output_vcf="${WORKING_DIRECTORY}/${OUTFILE_NAME}_predictions${CHR}.csv"
	}
}


task MergeCSV {
	input {
		Array[File] CSVList
		String samplenam
	}
	
	command {
		set -e
		
		cat ${sep=' ' CSVList} | grep -v "Chromosome" > ${samplenam}.csv
		
		# for output header
		cat ${sep=' ' CSVList} | grep "Chromosome" | head -n 1 > header
		
		cat header ${samplenam}.csv > ${samplenam}_predictions.csv
		
	}
	
	runtime {
		docker: "ubuntu:latest"
		cpu: 2
		memory: "10 GB"
		disk: "30 GB"
	}	
	
	output {
		File Prediction_output="${samplenam}_predictions.csv"
	}


}
