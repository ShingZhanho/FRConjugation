using System;
namespace JacobS.FRConjugation {
    /// <summary>The bundled conjugation catalogue could not be loaded.</summary>
    public sealed class ConjugationException : InvalidOperationException {
        /// <summary>Create a loading failure preserving the underlying resource/decoder error.</summary>
        public ConjugationException(string message, Exception innerException) : base(message, innerException) { }
    }
}
