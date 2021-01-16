

#ifndef NCRANDOMFOREST_H_
#define NCRANDOMFOREST_H_
#define _USE_MATH_DEFINES

#include <stdlib.h>
#include <math.h>

typedef struct NCRandomForests {
	int     nTrees;				 // Number of trees
	int     nClasses;            // Number of noise classes
	int     classDecision;       // Classifier output result
	int*  	treeVotes;           // class vote from each tree for debug
} NCRandomForests;

/*!
 * Initializes the Random Forest Classifier
 * 
 * This function initializes the Random Forest Classifier and sets
 * the parameters for the different trees
 *
 * @return pointer to initialized Random Forest Classifier
 *
 */
NCRandomForests* initNCRandomForest();

/*!
 * Predicts the class based on the features provided
 *
 * This function accepts the feature vector and then classifies the vector.
 * The classification output is stored in the classDecision variable of
 * the random forest structure
 *
 * @param RandomForest pointer to initialized Random Forest Classifier
 * @param inputFeatureList The features based on which the classifier makes
 *                         a decision
 * 
 *
 */
void evalNCTrees(NCRandomForests* RandomForest, float* inputFeatureList);
const char* returnNCClassLabel(int classIndex);
void destroyNCRandomForest(NCRandomForests** rf);

#endif /* NCRANDOMFOREST_H_ */
